return {
  {
    "pwntester/octo.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      -- OR 'ibhagwan/fzf-lua',
      -- OR 'folke/snacks.nvim',
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup({
        mappings = {
          issue = {
            add_comment = { lhs = "<leader>oa", desc = "add comment" },
          },
        },
      })
    end,
  },
}
