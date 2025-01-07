return {
  {
    "vinnymeller/swagger-preview.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("swagger-preview").setup({
        port = 8003,
        host = "localhost",
      })
    end,
  },
}
