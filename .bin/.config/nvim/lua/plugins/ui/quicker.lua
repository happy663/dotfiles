return {
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
    cond = vim.g.not_in_vscode,
    config = function()
      require("quicker").setup()
    end,
  },
}
