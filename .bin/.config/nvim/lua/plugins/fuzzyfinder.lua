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
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
            file_ignore_patterns = { "node_modules/*", "startuptime-logs/*" },
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
    keys = {
      {
        "<C-p>",
        "<cmd>lua require('telescope').extensions['recent-files'].recent_files({})<CR>",
      },
    },
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
}
