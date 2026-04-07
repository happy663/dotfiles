return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ia"] = "@assignment.inner",
              ["aa"] = "@assignment.outer",
              ["lh"] = "@assignment.lhs",
              ["rh"] = "@assignment.rhs",
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
              ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
              ["ib"] = { query = "@codeblock.inner", desc = "Select inner part of a code block" },
              ["ab"] = { query = "@codeblock.outer", desc = "Select around a code block" },
            },
            selection_modes = {
              ["@parameter.outer"] = "v", -- charwise
              ["@function.outer"] = "V", -- linewise
              ["@class.outer"] = "<c-v>", -- blockwise
              ["@codeblock.outer"] = "V", -- linewise
            },
            include_surrounding_whitespace = true,
          },
        },
      })
    end,
  },
}
