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

      local function is_lower_priority_comparator(entry1, entry2)
        local word1, word2 = entry1:get_word(), entry2:get_word()
        local function is_lower(char)
          return char:match("%l") ~= nil
        end

        if is_lower(word1:sub(1, 1)) and not is_lower(word2:sub(1, 1)) then
          return true
        elseif not is_lower(word1:sub(1, 1)) and is_lower(word2:sub(1, 1)) then
          return false
        end

        return nil
      end

      local default_comparators = {
        cmp.config.compare.locality,
        cmp.config.compare.exact,
        cmp.config.compare.offset,
        cmp.config.compare.score,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
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
        sorting = {
          priority_weight = 2,
          comparators = default_comparators,
        },
      })

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
        sorting = {
          priority_weight = 1,
          comparators = default_comparators,
        },
      })

      cmp.setup({
        snippet = {
          expand = function(args)
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
          { name = "vimtex" },
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
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "skkeleton", max_item_count = 10 },
            }),
            sorting = {
              priority_weight = 1,
              comparators = {
                cmp.config.compare.offset,
                cmp.config.compare.exact,
                cmp.config.compare.score,
                cmp.config.compare.kind,
              },
            },
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
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "path" },
              { name = "buffer" },
              { name = "codecompanion_models" },
              { name = "codecompanion_slash_commands" },
              { name = "codecompanion_tools" },
              { name = "codecompanion_variables" },
              { name = "vimtex" },
              { name = "render-markdown" },
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
            }),
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
      "f3fora/cmp-spell",
    },
  },
}
