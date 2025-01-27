return {
  {
    "hrsh7th/nvim-cmp",
    cond = vim.g.not_in_vscode,
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
      local luasnip = require("luasnip")
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
        sorting = {
          priority_weight = 1,
          comparators = {
            function(entry1, entry2)
              local word1 = entry1:get_word()
              local word2 = entry2:get_word()
              -- 小文字かどうかを判断する関数
              local function is_lower(char)
                return char:match("%l") ~= nil
              end
              -- 小文字で始まる項目を優先
              if is_lower(word1:sub(1, 1)) and not is_lower(word2:sub(1, 1)) then
                return true
              elseif not is_lower(word1:sub(1, 1)) and is_lower(word2:sub(1, 1)) then
                return false
              end

              return nil
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
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
        sorting = {
          priority_weight = 1,
          comparators = {
            function(entry1, entry2)
              local word1 = entry1:get_word()
              local word2 = entry2:get_word()
              -- 小文字かどうかを判断する関数
              local function is_lower(char)
                return char:match("%l") ~= nil
              end
              -- 小文字で始まる項目を優先
              if is_lower(word1:sub(1, 1)) and not is_lower(word2:sub(1, 1)) then
                return true
              elseif not is_lower(word1:sub(1, 1)) and is_lower(word2:sub(1, 1)) then
                return false
              end

              return nil
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
            -- vim.fn["vsnip#anonymous"](args.body)
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
            if luasnip.locally_jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "vsnip" },
          { name = "path" },
          { name = "buffer" },
          sources = {
            { name = "vimtex" },
          },
          {
            name = "spell",
            option = {
              keep_all_entries = false,
              enable_in_context = function()
                return true
              end,
              preselect_correct_word = true,
            },
          },
        },
        formatting = {
          -- expandable_indicator = true,
          -- fields = {},
          format = lspkind.cmp_format({
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = "...",
            show_labelDetails = true,
          }),
        },
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-enable-pre",
        callback = function()
          local cmp = require("cmp")
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "skkeleton", max_item_count = 5 },
            }),
          })
          cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = "skkeleton" },
            },
          })
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-disable-pre",
        callback = function()
          local cmp = require("cmp")
          cmp.setup.buffer({
            debug = true,
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "path" },
              { name = "buffer" },
              { name = "codecompanion_models" },
              { name = "codecompanion_slash_commands" },
              { name = "codecompanion_tools" },
              { name = "codecompanion_variables" },
              { name = "vimtex" },
            }),
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
      "onsails/lspkind.nvim",
      "uga-rosa/cmp-skkeleton",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
      "micangl/cmp-vimtex",
      -- "f3fora/cmp-spell",
    },
  },
}
