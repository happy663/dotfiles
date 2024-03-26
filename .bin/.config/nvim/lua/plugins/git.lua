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
}
