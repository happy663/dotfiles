return {
  {
    "williamboman/mason.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("mason").setup({
        ui = {
          border = "double",
          height = 0.8,
          width = 0.8,
        },
      })
    end,
  },
}
