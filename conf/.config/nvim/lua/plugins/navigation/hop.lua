return {
  {
    -- TODO: pluginsがarchiveされているので、代替を探す
    "phaazon/hop.nvim",
    branch = "v2", -- optional but strongly recommended
    config = function()
      local hop = require("hop")
      hop.setup({ keys = "etovxqpdygfblzhckisuran" })

      -- 日本語対応のカスタムHopWord関数
      local function hop_japanese_words()
        local jump_target = require("hop.jump_target")
        -- 日本語の文節パターン（Vimの正規表現）
        -- ひらがなの塊、カタカナの塊、漢字の塊、英数字の塊をそれぞれマッチ
        local pattern = "[ぁ-ん]\\+\\|[ァ-ヶー]\\+\\|[一-龥々〆〇]\\+\\|[a-zA-Z0-9]\\+"

        -- hop.optsを継承したオプションを使用
        local opts = setmetatable({}, { __index = hop.opts })

        hop.hint_with(jump_target.jump_targets_by_scanning_lines(jump_target.regex_by_searching(pattern)), opts)
      end

      -- 日本語対応版HopWordをメインキーに設定
      vim.keymap.set("n", "<leader>f", hop_japanese_words, {
        noremap = true,
        silent = true,
        desc = "Hop Words (日本語対応)",
      })

      -- 元のHopWordも使えるように別キーで保持
      vim.keymap.set("n", "<leader>F", "<CMD>HopWord<CR>", {
        noremap = true,
        silent = true,
        desc = "Hop Word (Original)",
      })
    end,
  },
}


