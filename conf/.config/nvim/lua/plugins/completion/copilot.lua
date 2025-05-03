return {
  {
    "zbirenbaum/copilot.lua",
    cmd = { "Copilot" },
    event = { "InsertEnter" },
    cond = vim.g.not_in_vscode,
    config = function()
      -- グローバル変数を設定してCopilotの状態を管理
      vim.g.copilot_enabled = true

      -- Copilotをトグルする関数
      function _G.toggle_copilot()
        if vim.g.copilot_enabled then
          vim.g.copilot_enabled = false
          local function disabled()
            vim.cmd("Copilot disable")
          end

          -- エラーを表示を回避する
          pcall(disabled)
          vim.notify("Copilot disabled", vim.log.levels.INFO)
        else
          vim.g.copilot_enabled = true
          vim.cmd("Copilot enable")
          vim.notify("Copilot enabled", vim.log.levels.INFO)
        end
      end

      -- Copilotのセットアップ
      require("copilot").setup({
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
            next = "<M-CR>",
          },
        },
        -- filetypesはトップレベルに設定
        filetypes = {
          -- デフォルト設定に追加
          gitcommit = true,
          tex = false,
          markdown = false,
          -- ["copilot-chat"] = true, -- copilot-chatを明示的に有効化
        },
      })

      -- トグル用のキーマップを設定
      vim.keymap.set("n", "<leader>tc", "<cmd>lua toggle_copilot()<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle Copilot",
      })
    end,
  },
}
