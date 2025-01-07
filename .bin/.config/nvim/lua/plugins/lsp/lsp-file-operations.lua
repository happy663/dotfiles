return {
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-tree.lua",
    },
    cond = vim.g.not_in_vscode,
    config = true,
  },
}
