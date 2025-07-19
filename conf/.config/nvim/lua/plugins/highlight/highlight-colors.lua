return {
  {
    "brenoprata10/nvim-highlight-colors",
    cond = vim.g.not_in_vscode,
    lazy = true,
    ft = { "css", "scss", "html", "javascript", "typescript", "vue", "svelte" },
    config = true,
  },
}
