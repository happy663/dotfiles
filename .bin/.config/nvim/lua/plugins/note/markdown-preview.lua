return {
  {
    "iamcco/markdown-preview.nvim",
    cond = vim.g.not_in_vscode,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
}
