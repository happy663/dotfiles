return {
  {
    -- "zbirenbaum/copilot.lua",
    -- cmd = { "Copilot" },
    -- event = { "InsertEnter" },
    -- opts = {
    --   filetypes = {
    --     gitcommit = true,
    --   },
    -- },
    -- config = true
  },
  {
    "github/copilot.vim",
    cond = vim.g.not_in_vscode,
  },
  {
    "hrsh7th/nvim-cmp",
    cond = vim.g.not_in_vscode,
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      -- `:` cmdline setup.
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
        }),
      })
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
        sorting = {
          comparators = {
            function(entry1, entry2)
              local input = vim.fn.getcmdline() -- 現在のコマンドライン入力を取得
              local prefix1 = entry1:get_completion_item().label:sub(1, #input) == input
              local prefix2 = entry2:get_completion_item().label:sub(1, #input) == input
              if prefix1 and not prefix2 then
                return true
              elseif not prefix1 and prefix2 then
                return false
              end
            end,
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
      })
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
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "vsnip" },
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
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "onsails/lspkind.nvim",
      "uga-rosa/cmp-skkeleton",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
    },
  },
  {
    "windwp/nvim-ts-autotag",
    cond = vim.g.not_in_vscode,
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "windwp/nvim-autopairs",
    cond = vim.g.not_in_vscode,
    config = true,
  },
}
