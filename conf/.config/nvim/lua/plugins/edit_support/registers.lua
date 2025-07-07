return {
  {
    "tversteeg/registers.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    keys = {
      { '"', mode = { "n", "v" } },
      { "@", mode = "n" },
    },
    config = function()
      require("registers").setup()
    end,
  },
}
