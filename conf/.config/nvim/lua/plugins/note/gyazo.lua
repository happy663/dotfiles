return {
  {
    "skanehira/gyazo.vim",
    cond = vim.g.not_in_vscode,
    keys = {
      { "<leader>gy", "<Plug>(gyazo-upload)", desc = "Upload to Gyazo", mode = "n" },
    },
    config = function()
      vim.g.gyazo_insert_markdown_url = 1
    end,
  },
}
