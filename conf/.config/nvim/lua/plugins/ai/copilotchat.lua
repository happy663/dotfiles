return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      -- サジェストが二重に表示されるのでコメントアウト
      -- { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    -- See Commands section for default commands if you want to lazy load on them
    config = function()
      require("CopilotChat").setup({
        mappings = {
          complete = false, -- Disable the default completion mapping
        },
      })

      -- Optional: Set up keymaps
      vim.keymap.set("n", "<leader>ss", "<cmd>CopilotChatToggle<cr>", { desc = "Copilot Chat" })
      vim.keymap.set("v", "<leader>ss", "<cmd>CopilotChatToggle<cr>", { desc = "Copilot Chat" })
    end,
  },
}
