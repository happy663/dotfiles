-- nvim-treesitter: 導入言語を明示列挙し、パーサとクエリのズレを防ぐ（issue #328）
--
-- パーサ（コンパイル済み .so）とクエリ（.scm）は更新経路が別で、クエリだけ先に新しくなると
-- 「クエリが参照するノードをパーサが持たない」状態になり、その言語のハイライトが丸ごと失敗する。
-- 実際に diff の (change) ノードで発生した。そのため tier 指定（全言語）ではなく導入言語を列挙し、
-- 起動時とプラグイン更新時に install/update で同期させる。
--
-- 列挙する言語の根拠: shada / file_frecency の実測（lua, ts, nix, md, json, sh, astro, scala,
-- php, py, tex, toml）と、dotfiles のプラグイン構成（lazygit/octo の gitcommit 系）。
-- Neovim 本体が同梱する言語（c, diff, lua, markdown, markdown_inline, query, vim, vimdoc）も
-- nvim-treesitter 側に寄せて一元管理する（本体同梱より indents/locals などのクエリが揃う）。
-- php_only / html_tags / ecma / jsx は requires から自動で追加される。
local LANGS = {
  -- Neovim 本体が同梱する言語
  "c",
  "diff",
  "lua",
  "markdown",
  "markdown_inline",
  "query",
  "vim",
  "vimdoc",
  -- 設定・データ
  "json",
  "yaml",
  "toml",
  "ssh_config",
  "regex",
  "comment",
  -- シェル
  "bash",
  "zsh",
  -- git（lazygit / octo / gitcommit）
  "gitcommit",
  "gitignore",
  "git_config",
  "git_rebase",
  -- Web
  "php",
  "twig",
  "html",
  "css",
  "javascript",
  "typescript",
  "tsx",
  "astro",
  -- その他
  "nix",
  "python",
  "scala",
  "latex",
  "luadoc",
  -- ビルド系
  "make",
  "dockerfile",
}

-- 導入言語の highlights クエリをコンパイルし、パーサとの不整合を検出する。
-- クエリがパーサに無いノード型を参照していると、ここでエラーになる（issue #328 の検知手段）。
local function check_parsers()
  local failed = {}
  for _, lang in ipairs(LANGS) do
    local ok, err = pcall(vim.treesitter.query.get, lang, "highlights")
    if not ok then
      local first_line = vim.split(tostring(err), "\n")[1]
      table.insert(failed, string.format("  %s: %s", lang, first_line))
    end
  end

  if #failed == 0 then
    vim.notify(
      string.format("[treesitter] %d 言語すべてでパーサとクエリが一致しています", #LANGS),
      vim.log.levels.INFO
    )
    return
  end

  vim.notify(
    string.format(
      "[treesitter] パーサとクエリが不一致です (%d/%d)\n%s",
      #failed,
      #LANGS,
      table.concat(failed, "\n")
    ),
    vim.log.levels.WARN
  )
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- リライト版（リポジトリはアーカイブ済み。core後継が出たら移行する）
    lazy = false, -- mainブランチはlazy-load非対応
    build = function()
      -- プラグイン更新時に pin が動いた言語だけ再ビルドする。
      -- 起動時の update と二重化しておく（lazy の build は nvim-treesitter 側の
      -- 非同期処理を取りこぼすことがあるため、これだけに依存しない）
      require("nvim-treesitter").update(LANGS)
    end,
    config = function()
      -- 未導入の言語を入れる（初回セットアップ・言語追加時）
      require("nvim-treesitter").install(LANGS)
      -- pin が動いた言語だけ再ビルドして、クエリとパーサを揃える。
      -- 揃っていれば revision の照合だけで終わる（実測 約1.5ms）
      require("nvim-treesitter").update(LANGS)

      -- ハイライトはNeovim本体の機能になったため、FileTypeごとに有効化する
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if vim.g.vscode then
            return
          end
          local lang = vim.treesitter.language.get_lang(args.match)
          if lang then
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end,
      })

      -- Treesitter folding settings
      vim.opt.foldmethod = "expr"
      vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"

      vim.api.nvim_create_user_command("TSCheck", check_parsers, {
        desc = "導入言語のパーサとクエリの整合性を確認する",
      })
    end,
  },
}
