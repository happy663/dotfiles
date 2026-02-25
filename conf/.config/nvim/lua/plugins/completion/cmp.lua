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
      -- -- パフォーマンス最適化設定
      vim.opt.completeopt = { "menu", "menuone", "noselect" }
      vim.opt.shortmess:append("c")
      -- skkeleton候補選択追跡用のグローバル変数
      local skkeleton_last_selected = nil
      local skkeleton_last_registered = nil

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

      -- REFACTOR: デフォルト設定を変数にまとめる
      local default_sorting = {
        priority_weight = 2,
        comparators = {
          cmp.config.compare.exact,
          cmp.config.compare.offset,
          cmp.config.compare.score,
          cmp.config.compare.recently_used,
          cmp.config.compare.locality,
          -- cmp.config.compare.kind,
          lspkind_comparator(),
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      }

      -- HACK: 現状sourceが2つある,本当は同じsourceを初期sourceに入れたい
      -- それをやるとcodecompanionなどのプラグイン側がソースを読み込んでいるので2つ同じソースが読み込まれるようになってしまう
      -- 現状無駄があるので共通のsourceは切り出してそれぞれで読み込みようにしたい
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
        { name = "codecompanion_acp_commands", group_index = 1 },
        { name = "avante_commands" },
        { name = "avante_mentions" },
        { name = "avante_files" },
        { name = "vimtex", group_index = 1 },
        { name = "render-markdown", group_index = 1 },
        { name = "calc", group_index = 1 },
        { name = "git", group_index = 1 },
        { name = "luasnip", group_index = 1 },
        -- {
        --   name = "spell",
        --   option = {
        --     keep_all_entries = false,
        --     enable_in_context = function()
        --       return true
        --     end,
        --     preselect_correct_word = true,
        --   },
        --   group_index = 2,
        -- },
        {
          name = "rg",
          group_index = 1,
          option = {
            additional_arguments = {
              "--hidden",
              "--glob",
              "!.git/",
              "--glob",
              "!*lock.json",
              "--glob",
              "!.p10k.zsh",
              "--glob",
              "!*startuptime-logs/",
              "--glob",
              "!*.L",
              "--glob",
              "!*.plist",
            },
          },
        },
        -- other sources
        {
          name = "dictionary",
          keyword_length = 2,
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
          -- ["<C-p>"] = cmp.mapping.select_prev_item(),
          -- ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
              -- skkeleton候補選択を追跡
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
              -- skkeleton候補選択を追跡
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
          -- copilotとの競合回避のためTabキー無効化
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
          -- {
          --   name = "spell",
          --   option = {
          --     keep_all_entries = false,
          --     enable_in_context = function()
          --       return true
          --     end,
          --     preselect_correct_word = true,
          --   },
          --   group_index = 2,
          -- },
          {
            name = "rg",
            group_index = 1,
            option = {
              additional_arguments = {
                "--hidden",
                "--glob",
                "!.git/",
                "--glob",
                "!*lock.json",
                "--glob",
                "!.p10k.zsh",
                "--glob",
                "!*startuptime-logs/",
                "--glob",
                "!*.L",
                "--glob",
                "!*.plist",
              },
            },
          },
          { name = "git", group_index = 1 },
          {
            name = "dictionary",
            keyword_length = 2,
            group_index = 1,
          },
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
          debounce = 150, -- デフォルト60ms → 150msに延長（入力遅延を軽減）
          throttle = 60, -- デフォルト30ms → 60msに延長
          fetching_timeout = 500, -- デフォルト200ms → 500msに延長
          max_view_entries = 20,
        },
      })

      -- skkeleton候補選択登録ヘルパー関数
      local function register_skkeleton_selection()
        -- skkeleton#is_enabled のチェックを削除（InsertLeave時に無効化されるため）
        if skkeleton_last_selected then
          local kana = skkeleton_last_selected.filterText
          local word = skkeleton_last_selected.label
          local key = kana .. "->" .. word

          -- 重複登録防止
          if skkeleton_last_registered ~= key then
            vim.fn["denops#request"]("skkeleton", "registerHenkanResult", { kana, word })
            skkeleton_last_registered = key
          else
          end

          -- 補完確定後に▽が残る問題を解決
          local cursor = vim.api.nvim_win_get_cursor(0)
          local line = vim.api.nvim_get_current_line()

          -- 行内の▽を探して削除
          local delta_pos = line:find("▽")
          if delta_pos then
            -- ▽を削除（▽は3バイトのUTF-8文字）
            local delta_end = delta_pos + 2
            vim.api.nvim_buf_set_text(0, cursor[1] - 1, delta_pos - 1, cursor[1] - 1, delta_end, {})
          end

          skkeleton_last_selected = nil
        end
      end

      -- skkeleton候補選択確定の追跡（条件付き実行でラグ防止）
      vim.api.nvim_create_autocmd("TextChangedI", {
        callback = function()
          -- 候補が選択されている場合のみ処理（ラグ防止）
          if skkeleton_last_selected and not cmp.visible() then
            register_skkeleton_selection()
          end
        end,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
          -- フォールバック処理
          if skkeleton_last_selected then
            register_skkeleton_selection()
          end
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-enable-pre",
        callback = function()
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "skkeleton", max_item_count = 20 },
            }),
            sorting = {
              priority_weight = 1,
              comparators = {
                cmp.config.compare.sort_text,
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
                cmp.config.compare.sort_text,
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
      -- "uga-rosa/cmp-skkeleton",
      -- "happy663/cmp-skkeleton",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
      "micangl/cmp-vimtex",
      {
        "uga-rosa/cmp-dictionary",
        cond = vim.g.not_in_vscode,
        config = function()
          require("cmp_dictionary").setup({
            paths = {
              -- "$HOME/dict.txt",
              "/usr/share/dict/words",
              -- "/usr/share/dict/web2",
            },
            exact_length = 2,
          })
        end,
      },
      -- "f3fora/cmp-spell",
      {
        "happy663/cmp-rg",
      },
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
      {
        dir = "~/src/github.com/happy663/cmp-skkeleton",
      },
    },
  },
}