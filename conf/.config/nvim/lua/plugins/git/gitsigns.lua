return {
  {
    "lewis6991/gitsigns.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },
}
