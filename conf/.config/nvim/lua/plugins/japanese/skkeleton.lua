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
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-pre",
        callback = function()
          vim.fn["skkeleton#config"]({
            globalDictionaries = {
              { "~/.config/skk/dictionary/SKK-JISYO.emoji.utf8", "utf-8" },
              { "~/.config/skk/dictionary/SKK-JISYO.L", "euc-jp" },
            },
            eggLikeNewline = true,
            userDictionary = "~/.config/skk/dictionary/userDict",
            globalKanaTableFiles = { { "~/.config/skk/azik_us.rule", "euc-jp" } },
            completionRankFile = "~/.config/skk/dictionary/userCompletionRankFile.json",
            immediatelyOkuriConvert = true,
            sources = {
              "skk_dictionary",
              "google_japanese_input",
            },
            keepState = true,
            debug = false,
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
