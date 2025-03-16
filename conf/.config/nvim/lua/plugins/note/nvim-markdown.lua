return {
  {
    "ixru/nvim-markdown",
    cond = vim.g.not_in_vscode,
    config = function()
      -- vim.g.vim_markdown_no_default_key_mappings = 1
      -- vim.keymap.set("n", "<Plug>Markdown_FollowLink", "<Plug>", {})
      -- Normal mode
      -- vim.keymap.set("n", "]]", "<Plug>Markdown_MoveToNextHeader")
      -- vim.keymap.set("n", "[[", "<Plug>Markdown_MoveToPreviousHeader")
      -- vim.keymap.set("n", "][", "<Plug>Markdown_MoveToNextSiblingHeader")
      -- vim.keymap.set("n", "[]", "<Plug>Markdown_MoveToPreviousSiblingHeader")
      -- vim.keymap.set("n", "]c", "<Plug>Markdown_MoveToCurHeader")
      -- vim.keymap.set("n", "]u", "<Plug>Markdown_MoveToParentHeader")
      -- vim.keymap.set("n", "<C-c>", "<Plug>Markdown_Checkbox")
      -- vim.keymap.set("n", "<Tab>", "<Plug>Markdown_Fold")
      -- vim.keymap.set("n", "<CR>", "<Plug>Markdown_FollowLink")
      --
      -- -- Insert mode
      -- vim.keymap.set("i", "<Tab>", "<Plug>Markdown_Jump")
      -- vim.keymap.set("i", "<C-k>", "<Plug>Markdown_CreateLink")
      -- vim.keymap.set("i", "O", "<Plug>Markdown_NewLineAbove")
      -- vim.keymap.set("i", "o", "<Plug>Markdown_NewLineBelow")
      -- vim.keymap.set("i", "<CR>", "<Plug>Markdown_NewLineBelow")
      --
      -- -- Visual mode
      -- vim.keymap.set("x", "<C-k>", "<Plug>Markdown_CreateLink")
    end,
  },
}
