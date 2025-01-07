return {
  {
    "mvllow/modes.nvim",
    version = "v0.2.0",
    config = true,
    cond = function()
      return not vim.g.vscode
    end,
  },
}
