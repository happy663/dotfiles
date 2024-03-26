-- 編集効率を高めるプラグイン

return {
  {
    "kylechui/nvim-surround",
    version = "*",
    config = true,
  },
  {
    "numToStr/Comment.nvim",
    config = true,
  },
  {
    "preservim/nerdcommenter",
  },
  {
    "tversteeg/registers.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("registers").setup()
    end,
  },
}
