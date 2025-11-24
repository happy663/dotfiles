return {
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    lazy = false,
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = function()
      local actions = require("diffview.actions")
      require("diffview").setup({
        keymaps = {
          view = {
            { "n", "q", actions.close, { desc = "ヘルプメニューを閉じる" } },
          },
          file_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "ヘルプメニューを閉じる" } },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "ヘルプメニューを閉じる" } },
          },
        },
      })
      vim.api.nvim_set_keymap("n", "<leader>df", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true })
    end,
  },
}
