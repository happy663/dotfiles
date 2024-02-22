return {
  {
    "github/copilot.vim",
    cond = function()
      return not vim.g.vscode
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp")

      cmp.setup({

        snippet = {
          expand = function(args)
            -- For vsnip users
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        mapping = {
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
        },
        sorting = {
          comparators = {
            cmp.config.compare.order,
            cmp.config.compare.kind,
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
          },
        },
      })
    end,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
    },
  },
  {
    "windwp/nvim-ts-autotag",
    config = true,
  },
  {
    "windwp/nvim-autopairs",
    config = true,
  },
}
