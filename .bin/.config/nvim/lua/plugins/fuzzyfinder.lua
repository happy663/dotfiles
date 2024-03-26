return {
  {
    "nvim-telescope/telescope.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
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
            num_pickers = 5,
          },
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
            file_ignore_patterns = { "node_modules/*" },
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
      require("telescope").load_extension("recent-files")
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mollerhoj/telescope-recent-files.nvim",
    },
    version = "0.1.5",
  },
  {
    "LukasPietzschmann/telescope-tabs",
    config = true,
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    config = function()
      require("telescope").load_extension("frecency")
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    run = "make",
  },
  {
    "delphinus/telescope-memo.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    config = function()
      require("telescope").load_extension("memo")
    end,
  },
  {
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    "ibhagwan/fzf-lua",
    dependencies = {
      "kyazdani42/nvim-web-devicons",
    },
  },
}
