return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
            ["@codeblock.outer"] = "V", -- linewise
          },
          include_surrounding_whitespace = true,
        },
      })

      -- mainブランチではキーマップを自前で定義する
      local function select_map(lhs, query, group, desc)
        vim.keymap.set({ "x", "o" }, lhs, function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, group or "textobjects")
        end, { desc = desc or query })
      end

      select_map("af", "@function.outer")
      select_map("if", "@function.inner")
      select_map("ia", "@assignment.inner")
      select_map("aa", "@assignment.outer")
      select_map("lh", "@assignment.lhs")
      select_map("rh", "@assignment.rhs")
      -- localsクエリのcapture名は @scope から @local.scope にリネームされた
      select_map("as", "@local.scope", "locals", "Select language scope")
      select_map("ic", "@codeblock.inner", nil, "Select inner part of a code block")
      select_map("ac", "@codeblock.outer", nil, "Select around a code block")
    end,
  },
}
