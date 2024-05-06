return {
  {
    "github/copilot.vim",
    cond = vim.g.not_in_vscode,
    opt = true,
  },
  {
    "hrsh7th/nvim-cmp",
    cond = vim.g.not_in_vscode,
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
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
            select = false,
          }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "path" },
          { name = "buffer" },
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
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol", -- show only symbol annotations
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            -- can also be a function to dynamically calculate max width such as
            -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
            ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
            show_labelDetails = true, -- show labelDetails in menu. Disabled by default
            -- The function below will be called before any actual modifications from lspkind
            -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
          }),
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
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "windwp/nvim-autopairs",
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "uga-rosa/cmp-skkeleton",
  },
}
