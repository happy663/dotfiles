return {
  {
    "hrsh7th/nvim-cmp",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = { "InsertEnter", "CmdlineEnter" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0,
      })
    end,
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      -- LuaSnipを遅延ロード
      local luasnip
      -- パフォーマンス最適化設定
      vim.opt.completeopt = { "menu", "menuone", "noselect" }
      vim.opt.shortmess:append("c")

      local lspkind_comparator = function(conf)
        local lsp_types = require("cmp.types").lsp
        return function(entry1, entry2)
          if entry1.source.name ~= "nvim_lsp" then
            if entry2.source.name == "nvim_lsp" then
              return false
            else
              return nil
            end
          end
          local kind1 = lsp_types.CompletionItemKind[entry1:get_kind()]
          local kind2 = lsp_types.CompletionItemKind[entry2:get_kind()]
          if kind1 == "Variable" and entry1:get_completion_item().label:match("%w*=") then
            kind1 = "Parameter"
          end
          if kind2 == "Variable" and entry2:get_completion_item().label:match("%w*=") then
            kind2 = "Parameter"
          end

          local priority1 = conf.kind_priority[kind1] or 0
          local priority2 = conf.kind_priority[kind2] or 0
          if priority1 == priority2 then
            return nil
          end
          return priority2 < priority1
        end
      end

      local default_sorting = {
        priority_weight = 2,
        comparators = {
          cmp.config.compare.exact,
          cmp.config.compare.offset,
          cmp.config.compare.score,
          cmp.config.compare.recently_used,
          cmp.config.compare.locality,
          -- cmp.config.compare.kind,
          lspkind_comparator({
            kind_priority = {
              Keyword = 14,
              Parameter = 13,
              Variable = 12,
              Field = 11,
              Property = 11,
              Constant = 10,
              Enum = 10,
              EnumMember = 10,
              Event = 10,
              Function = 10,
              Method = 10,
              Operator = 10,
              Reference = 10,
              Struct = 10,
              File = 8,
              Folder = 8,
              Class = 5,
              Color = 5,
              Module = 5,
              Constructor = 1,
              Interface = 1,
              Snippet = 0,
              Text = 1,
              TypeParameter = 1,
              Unit = 1,
              Value = 1,
            },
          }),
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      }

      local default_sources = {
        -- {
        --   name = "copilot",
        --   group_index = 1,
        -- },
        { name = "emoji", group_index = 1 },
        { name = "nvim_lsp", group_index = 1 },
        { name = "path", group_index = 1 },
        { name = "buffer", group_index = 1 },
        { name = "codecompanion_models", group_index = 1 },
        { name = "codecompanion_slash_commands", group_index = 1 },
        { name = "codecompanion_tools", group_index = 1 },
        { name = "codecompanion_variables", group_index = 1 },
        { name = "avante_commands" },
        { name = "avante_mentions" },
        { name = "avante_files" },
        { name = "vimtex", group_index = 1 },
        { name = "render-markdown", group_index = 1 },
        { name = "calc", group_index = 1 },
        { name = "git", group_index = 1 },
        { name = "luasnip", group_index = 1 },
        {
          name = "spell",
          option = {
            keep_all_entries = false,
            enable_in_context = function()
              return true
            end,
            preselect_correct_word = true,
          },
          group_index = 2,
        },
        {
          name = "rg",
          group_index = 1,
        },
      }

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
        default_sorting,
      })

      cmp.setup({
        -- enabled = function()
        --   local buftype = vim.api.nvim_buf_get_option(0, "buftype")
        --   if buftype == "prompt" then
        --     return true
        --   end
        --   return true
        -- end,
        snippet = {
          expand = function(args)
            if not luasnip then
              luasnip = require("luasnip")
            end
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if not luasnip then
              luasnip = require("luasnip")
            end
            if luasnip.locally_jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if not luasnip then
              luasnip = require("luasnip")
            end
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          -- ["<Tab>"] = cmp.mapping(function(fallback)
          --   -- luasnipが有効な場合のみcmpでTabキーを処理
          --   if not luasnip then
          --     luasnip = require("luasnip")
          --   end
          --   if luasnip.expand_or_jumpable() then
          --     luasnip.expand_or_jump()
          --   elseif cmp.visible() then
          --     cmp.select_next_item()
          --   else
          --     -- luasnipが無効な場合はcopilotにfallback
          --     fallback()
          --   end
          -- end, { "i", "s" }),
          -- ["<S-Tab>"] = cmp.mapping(function(fallback)
          --   if cmp.visible() then
          --     cmp.select_prev_item()
          --   else
          --     if not luasnip then
          --       luasnip = require("luasnip")
          --     end
          --     if luasnip.jumpable(-1) then
          --       luasnip.jump(-1)
          --     else
          --       fallback()
          --     end
          --   end
          -- end, { "i", "s" }),
        },

        sources = {
          -- {
          --   name = "copilot",
          --   group_index = 1,
          -- },
          { name = "luasnip", group_index = 1 },
          { name = "emoji", group_index = 1 },
          { name = "nvim_lsp", group_index = 1 },
          { name = "path", group_index = 1 },
          { name = "buffer", group_index = 1 },
          { name = "vimtex", group_index = 1 },
          { name = "render-markdown", group_index = 1 },
          { name = "calc", group_index = 1 },
          {
            name = "spell",
            option = {
              keep_all_entries = false,
              enable_in_context = function()
                return true
              end,
              preselect_correct_word = true,
            },
            group_index = 2,
          },
          {
            name = "rg",
            group_index = 1,
          },
          { name = "git", group_index = 1 },
        },
        sorting = default_sorting,
        formatting = {
          fields = {
            "abbr",
            "kind",
            "menu",
          },
          expandable_indicator = true,
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
          }),
        },
        -- 自動選択はしない
        preselect = cmp.PreselectMode.None,
        -- 補完候補が多すぎると邪魔なので制限
        performance = {
          max_view_entries = 10,
        },
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-enable-pre",
        callback = function()
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "skkeleton", max_item_count = 20 },
            }),
            sorting = {
              priority_weight = 2,
              comparators = {
                cmp.config.compare.exact,
                cmp.config.compare.score,
                cmp.config.compare.length,
              },
            },
            -- performance = {
            --   debounce = 10,
            --   throttle = 20,
            --   max_view_entries = 10,
            --   fetching_timeout = 50, -- ソースからの補完取得タイムアウト(ms)
            -- },
          })

          cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = "skkeleton" },
            },
            sorting = {
              priority_weight = 1,
              comparators = {
                cmp.config.compare.locality,
                cmp.config.compare.exact,
                cmp.config.compare.offset,
                cmp.config.compare.score,
              },
            },
          })
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-disable-pre",
        callback = function()
          cmp.setup.buffer({
            debug = true,
            sources = default_sources,
            sorting = default_sorting,
          })

          cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = "buffer" },
            },
          })
        end,
      })
    end,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-calc",
      "onsails/lspkind.nvim",
      "uga-rosa/cmp-skkeleton",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
      "micangl/cmp-vimtex",
      "f3fora/cmp-spell",
      "lukas-reineke/cmp-rg",
      "hrsh7th/cmp-emoji",
      "saadparwaiz1/cmp_luasnip",
      {
        "zbirenbaum/copilot-cmp",
        cond = vim.g.not_in_vscode,
        lazy = true,
        event = "InsertEnter",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
  },
}


