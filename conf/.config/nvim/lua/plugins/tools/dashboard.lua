return {
  {
    "nvimdev/dashboard-nvim",
    cond = vim.g.not_in_vscode and not vim.g.skip_dashboard,
    event = "VimEnter",
    config = function()
      require("dashboard").setup({})
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
}
