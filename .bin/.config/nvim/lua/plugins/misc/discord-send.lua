return {
  {
    "happy663/discord-send.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("discord-send.discord").setup({})
    end,
  },
}
