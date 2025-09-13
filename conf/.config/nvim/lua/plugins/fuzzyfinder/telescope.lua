return {
  {
    "nvim-telescope/telescope.nvim",
    cond = vim.g.not_in_vscode,
    cmd = { "Telescope" },
    lazy = true,
    config = function()
      local actions = require("telescope.actions")
      local state = require("telescope.actions.state")
      local builtin = require("telescope.builtin")

      -- Utility functions
      local function highlight_search_term(search_term)
        vim.fn.setreg("/", search_term)
        vim.cmd("set hlsearch")
      end

      -- Custom actions
      local custom_actions = {}
      function custom_actions.select_with_highlight()
        return function(prompt_bufnr)
          local search_term = state.get_current_line()
          actions.select_default(prompt_bufnr)
          highlight_search_term(search_term)
        end
      end

      function custom_actions.qf_and_highlight()
        return function(prompt_bufnr)
          actions.send_to_qflist(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
          local search_term = state.get_current_line()
          highlight_search_term(search_term)
        end
      end

      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              width = 0.9,
              preview_width = 0.4,
              prompt_position = "top",
            },
          },
          cache_picker = {
            num_pickers = 10,
          },
          mappings = {
            i = {
              ["<C-Tab>"] = actions.move_selection_next,
              ["<C-S-Tab>"] = actions.move_selection_previous,
              ["<C-J>"] = false, -- to support skkeleton.vim
              ["<C-o>"] = custom_actions.qf_and_highlight(),
              ["<C-f>"] = require("telescope.actions.layout").toggle_preview,
            },
            n = {
              ["<C-Tab>"] = actions.move_selection_next,
              ["<C-S-Tab>"] = actions.move_selection_previous,
            },
          },
          path_display = function(_, path)
            local tail = require("telescope.utils").path_tail(path)
            return string.format("%s (%s)", tail, path)
          end,
        },
        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--ignore-file",
              ".gitignore",
            },
            file_ignore_patterns = { "node_modules/*", "startuptime-logs/*", ".p10k.zsh" },
          },
          live_grep = {
            additional_args = function()
              return {
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
              }
            end,
            layout_config = {
              width = 0.9,
              preview_width = 0.5,
              height = 0.9,
            },
            mappings = {
              i = {
                -- 検索した単語をハイライトする
                ["<CR>"] = custom_actions.select_with_highlight(),
              },
              n = {
                -- 検索した単語をハイライトする
                ["<CR>"] = custom_actions.select_with_highlight(),
              },
            },
          },
          buffers = {
            sort_mru = true,
            default_selection_index = 2, -- 2番目のアイテムを初期選択
            layout_config = {
              horizontal = {
                width = 0.5,
                preview_width = 0,
                prompt_position = "top",
                height = 0.6,
              },
            },
            attach_mappings = function()
              return true
            end,
          },

          colorscheme = {
            enable_preview = true,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          smart_open = {
            open_buffer_indicators = { previous = "👀", others = "🙈" },
          },
          livegrep_history = {
            mappings = {
              up_key = "<Up>",
              down_key = "<Down>",
              confirm_key = "<CR>",
            },
            max_history = 100,
          },
        },
      })

      -- Helper functions
      _G.cycle_buffers = function(direction)
        local picker = state.get_current_picker()
        if picker == nil then
          builtin.buffers()
        else
          if direction == "next" then
            actions.move_selection_next(picker)
          else
            actions.move_selection_previous(picker)
          end
        end
      end

      -- Key mappings
      local keymaps = {
        -- Buffer cycling
        { "n", "<C-Tab>", [[<cmd>lua _G.cycle_buffers('next')<CR>]] },
        { "n", "<C-S-Tab>", [[<cmd>lua _G.cycle_buffers('previous')<CR>]] },
        -- Wezterm specific key sequences
        { "n", "<esc>[27;5;9~", [[<cmd>lua _G.cycle_buffers('next')<CR>]] },
        { "n", "<esc>[27;6;9~", [[<cmd>lua _G.cycle_buffers('previous')<CR>]] },
        -- Telescope commands
        { "n", "<Leader>td", "<cmd>Telescope diagnostics<CR>" },
        { "n", "<Leader>th", "<cmd>Telescope help_tags<CR>" },
      }

      for _, keymap in ipairs(keymaps) do
        vim.api.nvim_set_keymap(keymap[1], keymap[2], keymap[3], { noremap = true, silent = true })
      end

      vim.keymap.set("n", "<leader>tn", function()
        builtin.find_files({ cwd = vim.fn.expand("%:p:h") })
      end)
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      {
        "<C-g>",
        "<cmd>lua require('telescope.builtin').live_grep()<CR>",
      },
      {
        "<Leader>bg",
        "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<CR>",
      },
      {
        "<Leader>*",
        "<cmd>lua require('telescope.builtin').grep_string()<CR>",
      },
      {
        "<Leader>tb",
        "<cmd>lua require('telescope.builtin').buffers()<CR>",
      },
    },
    version = "0.1.5",
  },
  -- TODO Telescopeプラグインの整理をする
  {
    "mollerhoj/telescope-recent-files.nvim",
    cond = vim.g.not_in_vscode,
    -- keys = {
    --   {
    --     "<C-p>",
    --     "<cmd>lua require('telescope').extensions['recent-files'].recent_files({})<CR>",
    --   },
    -- },
  },
  -- {
  --   "LukasPietzschmann/telescope-tabs",
  --   lazy = true,
  --   keys = {
  --     { "<leader>ft", "<cmd>Telescope telescope-tabs list_tabs<cr>", desc = "List tabs" },
  --   },
  --   config = true,
  --   cond = vim.g.not_in_vscode,
  --   dependencies = {
  --     "nvim-telescope/telescope.nvim",
  --   },
  -- },
  -- {
  --   "nvim-telescope/telescope-frecency.nvim",
  --   cond = vim.g.not_in_vscode,
  --   lazy = true,
  --   -- 遅延ロード: frecency機能使用時のみ
  --   keys = {
  --     { "<leader>fr", "<cmd>Telescope frecency<cr>", desc = "Frecency" },
  --   },
  --   config = function()
  --     require("telescope").load_extension("frecency")
  --   end,
  -- },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    cond = vim.g.not_in_vscode,
    -- 遅延ロード: file_browser使用時のみ
    cmd = { "Telescope file_browser" },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    cond = vim.g.not_in_vscode,
    run = "make",
  },
  {
    "delphinus/telescope-memo.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    cond = vim.g.not_in_vscode,
    -- 遅延ロード: Memoコマンド使用時のみロード
    cmd = { "Memo" },
    config = function()
      require("telescope").load_extension("memo")
      -- Memoコマンドを定義
      vim.api.nvim_create_user_command("Memo", function()
        require("telescope").extensions.memo.memo()
      end, {})
    end,
  },
  {
    cond = vim.g.not_in_vscode,
    "ibhagwan/fzf-lua",
    dependencies = {
      "kyazdani42/nvim-web-devicons",
    },
  },
  {
    "danielfalk/smart-open.nvim",
    branch = "0.2.x",
    cond = vim.g.not_in_vscode,
    lazy = true,
    keys = {
      {
        "<C-p>",
        function()
          require("telescope").load_extension("smart_open")
          require("telescope").extensions.smart_open.smart_open()
        end,
        desc = "Smart Open",
      },
    },
    config = function()
      require("telescope").load_extension("smart_open")
    end,
    dependencies = {
      "kkharji/sqlite.lua",
      -- Only required if using match_algorithm fzf
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
      { "nvim-telescope/telescope-fzy-native.nvim" },
    },
  },
  {
    "happy663/telescope-livegrep-history.nvim", -- ローカルプラグインの名前
    -- dir = "~/src/github.com/happy663/telescope-livegrep-history.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    keys = {
      {
        "<C-g>",
        function()
          require("telescope").load_extension("livegrep_history")
          require("telescope").extensions.livegrep_history.live_grep_with_history()
        end,
        desc = "Live Grep with History",
      },
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("livegrep_history")
    end,
  },
}
