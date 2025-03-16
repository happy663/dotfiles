return {
  {
    "windwp/nvim-ts-autotag",
    cond = vim.g.not_in_vscode,
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
}
