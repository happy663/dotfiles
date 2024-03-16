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
            --vim.fn["vsnip#anonymous"](args.body)
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
          { name = "path" },
        },
        sorting = {
          priority_weight = 2,
          comparators = {
            function(entry1, entry2)
              local kind1 = entry1:get_kind()
              local kind2 = entry2:get_kind()
              local kindKeyword = vim.lsp.protocol.CompletionItemKind.Keyword
              local kindText = vim.lsp.protocol.CompletionItemKind.Text
              if kind1 == kindKeyword and kind2 ~= kindKeyword then
                return true
              elseif kind1 ~= kindKeyword and kind2 == kindKeyword then
                return false
              elseif kind1 == kindText and kind2 ~= kindText then
                return false
              elseif kind1 ~= kindText and kind2 == kindText then
                return true
              end
              -- 他の比較基準でソートする必要がある場合はnilを返す
              return nil
            end,
            cmp.config.compare.offset,
            cmp.config.compare.order,
            cmp.config.compare.kind,
            cmp.config.compare.score,
            -- 他の比較関数をここに追加
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
