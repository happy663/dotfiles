return {
  {
    "lewis6991/gitsigns.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>gb", "<cmd>Gitsigns blame_line<CR>", desc = "Git blame line" },
    },
    config = true,
  },
}
