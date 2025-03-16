return {
  {
    "tversteeg/registers.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("registers").setup()
    end,
  },
}
