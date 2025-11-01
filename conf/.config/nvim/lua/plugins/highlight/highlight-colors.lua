return {
  {
    "brenoprata10/nvim-highlight-colors",
    cond = vim.g.not_in_vscode,
    ft = { "css", "scss", "html", "javascript", "typescript", "vue", "svelte", "lua" },
    config = true,
  },
}
