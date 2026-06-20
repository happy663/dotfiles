return {
  {
    "happy663/skkeleton",
    -- dir = "/Users/happy/src/github.com/vim-skk/skkeleton/",
    -- dir = "/Users/happy/src/github.com/happy663/skkeleton",
    cond = vim.g.not_in_vscode,
    dependencies = {
      { "vim-denops/denops.vim" },
    },
    config = function()
      local opts = { noremap = false, silent = true }
      local function enable_skkeleton_on_terminal()
        if vim.bo.buftype == "terminal" and vim.api.nvim_get_mode().mode ~= "t" then
          return
        end
        if not vim.fn["skkeleton#is_enabled"]() then
          pcall(vim.fn["denops#request"], "skkeleton", "reset", {})
        end
        vim.fn["skkeleton#handle"]("enable", { key = { "<C-j>" } })
      end

      vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkeleton-enable)", opts)
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function()
          vim.keymap.set("t", "<C-j>", enable_skkeleton_on_terminal, opts)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-pre",
        callback = function()
          vim.fn["skkeleton#config"]({
            globalDictionaries = {
              { "~/.config/skk/dictionary/SKK-JISYO.emoji.utf8", "utf-8" },
              { "~/.config/skk/dictionary/SKK-JISYO.L", "euc-jp" },
            },
            eggLikeNewline = true,
            userDictionary = "~/src/github.com/ppha3260-web/my-skk-dict/userDict",
            globalKanaTableFiles = { { "~/.config/skk/azik_us.rule", "euc-jp" } },
            completionRankFile = "~/src/github.com/ppha3260-web/my-skk-dict/userCompletionRankFile.json",
            immediatelyOkuriConvert = true,
            sources = {
              -- 変換する時(getHenkanResult)の優先順位(cmp補完の候補の順番ではない)
              "skk_dictionary",
              "skk_server",
              -- skkserverが動いていないとエラーになる、google_japanese_inputにfallbackが望ましい
              "google_japanese_input",
            },
            keepState = true,
            debug = false,
            registerConvertResult = true,
            -- skkServerPortは数値リテラルで指定する (is.Numberバリデーション)。
            -- skkServerResEncはサーバ仕様によりUTF-8固定。
            -- 詳細: https://github.com/happy663/dotfiles/issues/255#issuecomment-4470747322
            skkServerHost = "127.0.0.1",
            skkServerPort = 1178,
            -- skkServerReqEnc = "euc-jp",
            -- skkServerResEnc = "utf-8",
          })

          vim.fn["skkeleton#register_kanatable"]("rom", {
            ["jj"] = "escape",
            ["z,"] = { "ー", "" },
            -- [","] = { "，", "" },
            -- ["."] = { "．", "" },
            ["q"] = "katakana",
            ["'"] = { "っ" },
            ["_"] = { "-" },
            ["："] = { ":" },
            ["zv"] = { "←" },
            ["zb"] = { "↓" },
            ["zn"] = { "↑" },
            ["zm"] = { "→" },
            ["sha"] = false,
            ["shi"] = false,
            ["shu"] = false,
            ["she"] = false,
            ["sho"] = false,
          })

          vim.api.nvim_exec(
            [[
      call add(g:skkeleton#mapped_keys, '<C-a>')
      ]],
            false
          )
          vim.fn["skkeleton#register_keymap"]("henkan", "<C-a>", "henkanForward")

          vim.keymap.set("t", "<C-y>", function()
            vim.fn.feedkeys(vim.fn.input("Input: "), "n")
          end)
        end,
      })
    end,
  },
}
