return {
  {
    "nvimdev/dashboard-nvim",
    cond = vim.g.not_in_vscode,
    event = "VimEnter",
    config = function()
      require("dashboard").setup({})
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
}
