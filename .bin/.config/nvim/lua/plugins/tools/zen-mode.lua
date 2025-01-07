return {
  {
    "folke/zen-mode.nvim",
    cond = vim.g.not_in_vscode,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    config = {
      vim.keymap.set("n", "<leader>zz", "<cmd>ZenMode<cr>", { noremap = true, silent = true }),
    },
  },
}
