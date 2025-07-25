return {
  {
    "kevinhwang91/nvim-hlslens",
    lazy = true,
    keys = { "n", "N", "*", "#", "/", "?" },
    config = function()
      require("hlslens").setup()

      vim.api.nvim_set_keymap(
        "n",
        "n",
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "N",
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        { noremap = true, silent = true }
      )
    end,
  },
}
