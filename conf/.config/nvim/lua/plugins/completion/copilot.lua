return {
  {
    "zbirenbaum/copilot.lua",
    lazy = true,
    event = "InsertEnter",
    cmd = { "Copilot" },
    keys = {
      { "<leader>tc", desc = "Toggle Copilot" },
    },
    cond = vim.g.not_in_vscode,
    config = function()
      local setup_config = {
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = false, -- Copilotの内部キーマップを無効化
            next = "<M-CR>",
          },
        },
        filetypes = {
          gitcommit = true,
          tex = false,
          markdown = false,
        },
      }

      -- Copilotのセットアップ（一度だけ）
      require("copilot").setup(setup_config)

      -- カスタムTabキーマップ - トグル後も機能する
      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          return vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
        end
      end, {
        silent = true,
        expr = true,
        desc = "Accept copilot suggestion or fallback to tab",
      })

      -- Copilotをトグルする関数
      function _G.toggle_copilot()
        if require("copilot.client").is_disabled() then
          -- 有効化
          require("copilot.command").enable()
          vim.notify("Copilot enabled", vim.log.levels.INFO)
        else
          -- 無効化（エラーを表示しないようにpcallでラップ）
          local function disabled()
            require("copilot.command").disable()
          end
          pcall(disabled)
          vim.notify("Copilot disabled", vim.log.levels.INFO)
        end
      end

      -- トグル用のキーマップを設定
      vim.keymap.set("n", "<leader>tc", "<cmd>lua toggle_copilot()<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle Copilot",
      })
    end,
  },
}
