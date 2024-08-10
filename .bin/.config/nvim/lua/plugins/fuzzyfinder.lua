return {
  {
    "nvim-telescope/telescope.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              width = 0.9,
              preview_width = 0.6,
              prompt_position = "top",
            },
          },
          cache_picker = {
            num_pickers = 10,
          },
          mappings = {
            i = {
              ["<C-J>"] = false, -- to support skkeleton.vim
            },
          },
        },
        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob",
              "!.git/*",
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
              }
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
        "<Leader>b",
        "<cmd>lua require('telescope.builtin').git_branches()<CR>",
      },
      {
        "<Leader>*",
        "<cmd>lua require('telescope.builtin').grep_string()<CR>",
      },
    },
    version = "0.1.5",
  },
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
