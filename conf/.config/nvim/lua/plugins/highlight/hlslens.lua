return {
  {
    "kevinhwang91/nvim-hlslens",
    lazy = true,
    keys = {
      "n",
      "N",
      "#",
      "/",
      "?",
      { "<ESC><ESC>", desc = "Toggle search highlight" },
    },
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

      -- Toggle highlight function
      vim.g.highlight_on = true
      function _G.Toggle_highlight()
        if vim.g.highlight_on then
          vim.cmd("nohlsearch")
          vim.cmd("HlSearchLensDisable")
          vim.g.highlight_on = false
        else
          vim.cmd("set hlsearch")
          vim.cmd("HlSearchLensEnable")
          vim.g.highlight_on = true
        end
      end

      vim.api.nvim_create_autocmd("CmdlineEnter", {
        pattern = { "/" },
        callback = function()
          vim.g.highlight_on = true
        end,
      })

      vim.keymap.set("n", "<ESC><ESC>", "<cmd>lua Toggle_highlight()<CR>", { noremap = true, silent = true })
    end,
  },
}
