return {
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    config = {
      vim.api.nvim_set_keymap("n", "<leader>dff", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true }),
      vim.api.nvim_set_keymap("n", "<leader>dfq", "<cmd>DiffviewClose<CR>", { noremap = true, silent = true }),
    },
  },
}
