return {
  {
    "lewis6991/gitsigns.nvim",
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "kdheepak/lazygit.nvim",
    cond = vim.g.not_in_vscode,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    config = {
      vim.api.nvim_set_keymap("n", "<leader>df", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true }),
    },
  },
}
