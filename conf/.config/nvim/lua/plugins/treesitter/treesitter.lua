return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- リライト版（リポジトリはアーカイブ済み。core後継が出たら移行する）
    lazy = false, -- mainブランチはlazy-load非対応
    build = ":TSUpdate",
    config = function()
      -- 旧 ensure_installed = "all" 相当（stable + unstable の全ティア）
      require("nvim-treesitter").install({ "stable", "unstable" })

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
    end,
  },
}
