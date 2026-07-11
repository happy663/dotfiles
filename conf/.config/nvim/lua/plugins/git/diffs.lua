-- diffs.nvim: treesitter-powered diff syntax highlighting
-- gitcommit filetype で guh.nvim の prdiff バッファをハイライトするために導入
return {
  {
    "barrettruth/diffs.nvim",
    lazy = true,
    ft = { "git", "gitcommit", "diff" },
  },
}
