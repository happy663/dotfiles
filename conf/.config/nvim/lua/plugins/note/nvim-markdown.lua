return {
  {
    "ixru/nvim-markdown",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.g.vim_markdown_no_default_key_mappings = 1

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "octo" },
        callback = function()
          vim.api.nvim_buf_set_keymap(0, "n", "<C-c>", "<Plug>Markdown_Checkbox", {
            noremap = true,
            silent = true,
            desc = "Markdown: Toggle checkbox",
          })

          vim.api.nvim_buf_set_keymap(0, "n", "<Tab>", "<Plug>Markdown_Fold", {
            noremap = true,
            silent = true,
            desc = "Markdown: Fold",
          })

          vim.api.nvim_buf_set_keymap(0, "n", "O", "<Plug>Markdown_NewLineAbove", {
            noremap = true,
            silent = true,
            desc = "Markdown: New line above",
          })

          vim.api.nvim_buf_set_keymap(0, "n", "o", "<Plug>Markdown_NewLineBelow", {
            noremap = true,
            silent = true,
            desc = "Markdown: New line below",
          })

          vim.api.nvim_buf_set_keymap(0, "i", "<C-k>", "<Plug>Markdown_CreateLink", {
            noremap = true,
            silent = true,
            desc = "Markdown: Create link",
          })
        end,
      })

      -- vim.keymap.set("n", "<Plug>Markdown_FollowLink", "<Plug>", {})
      -- Normal mode
      -- vim.keymap.set("n", "]]", "<Plug>Markdown_MoveToNextHeader")
      -- vim.keymap.set("n", "[[", "<Plug>Markdown_MoveToPreviousHeader")
      -- vim.keymap.set("n", "][", "<Plug>Markdown_MoveToNextSiblingHeader")
      -- vim.keymap.set("n", "[]", "<Plug>Markdown_MoveToPreviousSiblingHeader")
      -- vim.keymap.set("n", "]c", "<Plug>Markdown_MoveToCurHeader")
      -- vim.keymap.set("n", "]u", "<Plug>Markdown_MoveToParentHeader")
      vim.keymap.set("n", "<C-c>", "<Plug>Markdown_Checkbox")
      -- vim.keymap.set("n", "gx", "<Plug>Markdown_FollowLink")
      -- vim.keymap.set("n", "<Tab>", "<Plug>Markdown_Fold")
      -- vim.keymap.set("n", "O", "<Plug>Markdown_NewLineAbove")
      -- vim.keymap.set("n", "o", "<Plug>Markdown_NewLineBelow")
      --
      -- -- Insert mode
      -- vim.keymap.set("i", "<Tab>", "<Plug>Markdown_Jump")
      -- vim.keymap.set("i", "<C-k>", "<Plug>Markdown_CreateLink")
      -- vim.keymap.set("i", "<CR>", "<Plug>Markdown_NewLineBelow")
      --
      -- -- Visual mode
    end,
  },
}
