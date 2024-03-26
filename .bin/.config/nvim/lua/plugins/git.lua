return {
  {
    "lewis6991/gitsigns.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    config = true,
  },
  {
    "kdheepak/lazygit.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
