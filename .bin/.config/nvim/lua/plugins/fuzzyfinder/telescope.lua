return {
  {
    "nvim-telescope/telescope.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      local actions = require("telescope.actions")
      local state = require("telescope.actions.state")
      local builtin = require("telescope.builtin")

      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              width = 0.9,
              preview_width = 0.5,
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
              ["<C-o>"] = actions.send_to_qflist + actions.open_qflist,
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
          },
          buffers = {
            sort_mru = true,
            default_selection_index = 2, -- 2番目のアイテムを初期選択
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
        },
      })
      -- バッファ切り替え用の関数
      _G.cycle_buffers = function(direction)
        local picker = state.get_current_picker()
        if picker == nil then
          -- Telescope buffersが開いていない場合は開く
          builtin.buffers()
        else
          -- 既に開いている場合は選択を移動
          if direction == "next" then
            actions.move_selection_next(picker)
          else
            actions.move_selection_previous(picker)
          end
        end
      end

      -- キーマッピング（変更なし）
      vim.api.nvim_set_keymap(
        "n",
        "<C-Tab>",
        [[<cmd>lua _G.cycle_buffers('next')<CR>]],
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<C-S-Tab>",
        [[<cmd>lua _G.cycle_buffers('previous')<CR>]],
        { noremap = true, silent = true }
      )

      -- Weztermからの特殊なキー入力に対応（変更なし）
      vim.api.nvim_set_keymap(
        "n",
        "<esc>[27;5;9~",
        [[<cmd>lua _G.cycle_buffers('next')<CR>]],
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<esc>[27;6;9~",
        [[<cmd>lua _G.cycle_buffers('previous')<CR>]],
        { noremap = true, silent = true }
      )

      vim.api.nvim_set_keymap("n", "<Leader>td", "<cmd>Telescope diagnostics<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<Leader>th", "<cmd>Telescope help_tags<CR>", { noremap = true, silent = true })
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
        "<Leader>gb",
        "<cmd>lua require('telescope.builtin').git_branches()<CR>",
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
  {
    "LukasPietzschmann/telescope-tabs",
    config = true,
    cond = vim.g.not_in_vscode,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("telescope").load_extension("frecency")
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    cond = vim.g.not_in_vscode,
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
    config = function()
      require("telescope").load_extension("memo")
    end,
    key = {},
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
    config = function()
      require("telescope").load_extension("smart_open")
      vim.keymap.set("n", "<C-p>", function()
        require("telescope").extensions.smart_open.smart_open()
      end, { noremap = true, silent = true })
    end,
    dependencies = {
      "kkharji/sqlite.lua",
      -- Only required if using match_algorithm fzf
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
      { "nvim-telescope/telescope-fzy-native.nvim" },
    },
  },
}
