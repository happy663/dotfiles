return {
  {
    dir = "/Users/happy/src/github.com/happy663/octo-preview.nvim",
    dependencies = { "pwntester/octo.nvim" },
    config = function()
      require("octo-preview").setup({
        port = 6042,
      })
    end,
  },
}
