return {
  {
    "lewis6991/gitsigns.nvim",
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "kdheepak/lazygit.nvim",
    cond = vim.g.not_in_vscode,
    lazy = false,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension("lazygit")
    end,
  },
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    config = {
      vim.api.nvim_set_keymap("n", "<leader>df", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true }),
    },
  },
}
