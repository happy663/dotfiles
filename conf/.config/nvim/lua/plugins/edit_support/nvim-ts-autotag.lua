return {
  {
    "windwp/nvim-ts-autotag",
    cond = vim.g.not_in_vscode,
    lazy = true,
    ft = { "html", "xml", "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "svelte" },
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
}
