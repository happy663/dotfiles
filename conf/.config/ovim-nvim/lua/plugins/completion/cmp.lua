return {
  {
    "hrsh7th/nvim-cmp",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      local luasnip
      vim.opt.completeopt = { "menu", "menuone", "noselect" }
      vim.opt.shortmess:append("c")
      local skkeleton_last_selected = nil
      local skkeleton_last_registered = nil

      local function refresh_skkeleton_abbrev_completion()
        if vim.g["skkeleton#mode"] ~= "abbrev" then
          return
        end

        local mode = vim.api.nvim_get_mode().mode
        if mode ~= "i" and mode ~= "ic" then
          return
        end

        local state = vim.g["skkeleton#state"]
        if type(state) ~= "table" or state.phase ~= "input:okurinasi" then
          cmp.close()
          return
        end

        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local input = line:sub(1, col):match("([a-zA-Z]+)$")

        if input and #input > 0 then
          cmp.complete()
        else
          cmp.close()
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
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      }

      -- ターミナルバッファの内容も補完対象にする
      local function buffer_get_bufnrs()
        local bufs = { vim.api.nvim_get_current_buf() }
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
            table.insert(bufs, buf)
          end
        end
        return bufs
      end

      local buffer_source = {
        name = "buffer",
        group_index = 1,
        option = { get_bufnrs = buffer_get_bufnrs },
      }

      local default_sources = {
        { name = "luasnip", group_index = 1 },
        { name = "emoji", group_index = 1 },
        { name = "path", group_index = 1 },
        buffer_source,
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
        snippet = {
          expand = function(args)
            if not luasnip then
              luasnip = require("luasnip")
            end
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<C-p>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
              vim.schedule(function()
                local entry = cmp.get_selected_entry()
                if entry and entry.source.name == "skkeleton" then
                  skkeleton_last_selected = entry.completion_item
                end
              end)
            else
              fallback()
            end
          end, { "i" }),
          ["<C-n>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
              vim.schedule(function()
                local entry = cmp.get_selected_entry()
                if entry and entry.source.name == "skkeleton" then
                  skkeleton_last_selected = entry.completion_item
                end
              end)
            else
              fallback()
            end
          end, { "i" }),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm(),
          ["<C-j>"] = cmp.mapping(function(fallback)
            if not luasnip then
              luasnip = require("luasnip")
            end
            if luasnip.locally_jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-k>"] = cmp.mapping(function(fallback)
            if not luasnip then
              luasnip = require("luasnip")
            end
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-x>"] = cmp.mapping(function(fallback)
            local entry = cmp.get_selected_entry()
            if entry and entry.source.name == "skkeleton" then
              local label = entry.completion_item.label
              local kana = entry.completion_item.filterText
              require("cmp_skkeleton").purge_candidate(kana, label)
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
        },

        sources = default_sources,
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
        preselect = cmp.PreselectMode.None,
        performance = {
          debounce = 20,
          throttle = 30,
          fetching_timeout = 200,
          max_view_entries = 20,
        },
      })

      -- skkeleton候補選択登録ヘルパー関数
      local function register_skkeleton_selection()
        if skkeleton_last_selected then
          local kana = skkeleton_last_selected.filterText
          local word = skkeleton_last_selected.label
          local key = kana .. "->" .. word

          if skkeleton_last_registered ~= key then
            vim.fn["denops#request"]("skkeleton", "registerHenkanResult", { kana, word })
            skkeleton_last_registered = key
          end

          -- 補完確定後に▽が残る問題を解決
          local cursor = vim.api.nvim_win_get_cursor(0)
          local line = vim.api.nvim_get_current_line()

          local delta_pos = line:find("▽")
          if delta_pos then
            local delta_end = delta_pos + 2
            vim.api.nvim_buf_set_text(0, cursor[1] - 1, delta_pos - 1, cursor[1] - 1, delta_end, {})
          end

          skkeleton_last_selected = nil
        end
      end

      vim.api.nvim_create_autocmd("TextChangedI", {
        callback = function()
          if skkeleton_last_selected and not cmp.visible() then
            register_skkeleton_selection()
          end
        end,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
          if skkeleton_last_selected then
            register_skkeleton_selection()
          end
        end,
      })

      local DEFAULT_MAX_ENTRIES = 20

      local skkeleton_config = {
        sources = cmp.config.sources({
          { name = "skkeleton", max_item_count = DEFAULT_MAX_ENTRIES },
        }),
        sorting = {
          priority_weight = 1,
          comparators = {
            cmp.config.compare.sort_text,
          },
        },
      }

      local cmdline_config = {
        enable = {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = "skkeleton" },
          },
          sorting = {
            priority_weight = 1,
            comparators = {
              cmp.config.compare.sort_text,
            },
          },
        },
        disable = {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = "buffer" },
          },
        },
      }

      local function create_buffer_config(is_enabled)
        local config = {
          performance = {
            max_view_entries = DEFAULT_MAX_ENTRIES,
          },
        }

        if is_enabled then
          config.sources = skkeleton_config.sources
          config.sorting = skkeleton_config.sorting
        else
          config.sources = default_sources
          config.sorting = default_sorting
        end

        return config
      end

      local function setup_autocmd(pattern, is_enabled)
        vim.api.nvim_create_autocmd("User", {
          pattern = pattern,
          callback = function()
            cmp.setup.buffer(create_buffer_config(is_enabled))

            local cmdline_key = is_enabled and "enable" or "disable"
            cmp.setup.cmdline("/", cmdline_config[cmdline_key])
          end,
        })
      end

      setup_autocmd("skkeleton-enable-pre", true)
      setup_autocmd("skkeleton-disable-pre", false)

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-handled",
        callback = function()
          vim.schedule(refresh_skkeleton_abbrev_completion)
        end,
      })
    end,
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "onsails/lspkind.nvim",
      "happy663/cmp-skkeleton",
      "hrsh7th/cmp-emoji",
      "saadparwaiz1/cmp_luasnip",
    },
  },
}
