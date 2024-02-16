-- plugins.lua
require("packer").startup({
  function()
    use("wbthomason/packer.nvim")  -- Packer can manage itself
    use("easymotion/vim-easymotion") -- easymotion plugin
    use("skanehira/jumpcursor.vim")
    -- Color themes
    use("hrsh7th/vim-searchx")
    use("gruvbox-community/gruvbox")
    use("https://codeberg.org/miyakogi/iceberg-tokyo.nvim")
    use("Mofiqul/dracula.nvim")
    -- File tree
    use({
      "nvim-tree/nvim-tree.lua",
      requires = "nvim-tree/nvim-web-devicons", -- オプション: アイコン表示のため
      config = function()
        require("nvim-tree").setup({
          sort_by = "case_sensitive",
          view = {
            width = 30,
          },
          renderer = {
            group_empty = true,
          },
          filters = {
            dotfiles = false,
          },
        })
      end,
    })
    --Commenting
    use("preservim/nerdcommenter")
    -- LSP
    use("neovim/nvim-lspconfig")
    use("williamboman/mason.nvim")
    use("williamboman/mason-lspconfig.nvim")
    -- Completion
    use({
      "hrsh7th/nvim-cmp",
      requires = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
      },
    })

    -- FZF
    use({
      "ibhagwan/fzf-lua",
      requires = { "kyazdani42/nvim-web-devicons" },
    })
    use({ "kana/vim-operator-user" })
    use({ "kana/vim-operator-replace" })
    -- Auto pairs
    use({
      "windwp/nvim-autopairs",
      config = function()
        require("nvim-autopairs").setup({})
      end,
    })
    -- Bufferline
    use({
      "akinsho/bufferline.nvim",
      tag = "*",
      requires = "kyazdani42/nvim-web-devicons",
      config = function()
        require("bufferline").setup({})
      end,
    })

    use({
      "nvimtools/none-ls.nvim",
      config = function()
        require("null-ls").setup()
      end,
      requires = { "nvim-lua/plenary.nvim" },
    })

    use({
      "akinsho/toggleterm.nvim",
      tag = "*",
      config = function()
        require("toggleterm").setup({
          size = 20,
          open_mapping = [[<c-\>]],
          hide_numbers = true,
          shade_filetypes = {},
          shade_terminals = true,
          shading_factor = 2,
          start_in_insert = true,
          insert_mappings = true,
          persist_size = true,
          direction = "float",
          float_opts = {
            border = "curved",
            winblend = 0,
            highlights = {
              border = "Normal",
              background = "Normal",
            },
          },
        })
      end,
    })

    use({
      "lewis6991/gitsigns.nvim",
      tag = "*",
      config = function()
        require("gitsigns").setup({
          signs = {
            add = { text = "│" },
            change = { text = "│" },
            delete = { text = "_" },
            topdelete = { text = "‾" },
            changedelete = { text = "~" },
            untracked = { text = "┆" },
          },
          signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
          numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
          linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
          word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
          watch_gitdir = {
            follow_files = true,
          },
          --auto_attach = true,
          attach_to_untracked = false,
          current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
            virt_text_priority = 100,
          },
          current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
          sign_priority = 6,
          update_debounce = 100,
          status_formatter = nil, -- Use default
          max_file_length = 40000, -- Disable if file is longer than this (in lines)
          preview_config = {
            -- Options passed to nvim_open_win
            border = "single",
            style = "minimal",
            relative = "cursor",
            row = 0,
            col = 1,
          },
          yadm = {
            enable = false,
          },
        })
      end,
    })

    --レジスタ
    use({
      "tversteeg/registers.nvim",
      config = function()
        require("registers").setup()
      end,
    })

    --コードランナー
    use("CRAG666/code_runner.nvim")
    use("nvim-lua/plenary.nvim")

    -- コマンドラインを中央にする
    use({
      "folke/noice.nvim",
      --event = "VimEnter",
      config = function()
        -- add any options here
        require("noice").setup({
          lsp = {
            -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
            override = {
              ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
              ["vim.lsp.util.stylize_markdown"] = true,
              ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
            },
            hover = {
              enable = false,
            },
          },
          -- you can enable a preset for easier configuration
          presets = {
            bottom_search = true,   -- use a classic bottom cmdline for search
            command_palette = true, -- position the cmdline and popupmenu together
            long_message_to_split = true, -- long messages will be sent to a split
            inc_rename = false,     -- enables an input dialog for inc-rename.nvim
            lsp_doc_border = false, -- add a border to hover docs and signature help
          },
        })
      end,
      requires = {
        -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries in packer's use
        "MunifTanjim/nui.nvim",
        -- OPTIONAL:
        --   `nvim-notify` is only needed, if you want to use the notification view.
        --   If not available, we fallback to something else, but in packer, you just include it if needed.
        "rcarriga/nvim-notify",
      },
    })

    use("lukas-reineke/indent-blankline.nvim")

    use({
      "nvim-telescope/telescope.nvim",
      tag = "0.1.5",
      -- or                            , branch = '0.1.x',
      requires = { { "nvim-lua/plenary.nvim" } },
    })

    use({
      "LukasPietzschmann/telescope-tabs",
      requires = { "nvim-telescope/telescope.nvim" },
      config = function()
        require("telescope-tabs").setup({
          -- Your custom config :^)
        })
      end,
    })

    use({
      "nvim-telescope/telescope-frecency.nvim",
      config = function()
        require("telescope").load_extension("frecency")
      end,
    })

    use({
      "nvim-telescope/telescope-file-browser.nvim",
      requires = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    })

    use({
      "nvim-telescope/telescope-fzf-native.nvim",
      run = "make",
      requires = { "nvim-telescope/telescope.nvim" },
    })

    use({
      "numToStr/Comment.nvim",
      config = function()
        require("Comment").setup()
      end,
    })

    use({
      "github/copilot.vim",
      cond = function()
        return not vim.g.vscode
      end,
    })

    use({
      "nvim-treesitter/nvim-treesitter",
      run = function()
        local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
        ts_update()
      end,
    })

    use({
      "yuki-yano/fuzzy-motion.vim",
      requires = {
        "vim-denops/denops.vim",
      },
    })

    use({
      "kylechui/nvim-surround",
      tag = "*", -- Use for stability; omit to use `main` branch for the latest features
      config = function()
        require("nvim-surround").setup({
          -- Configuration here, or leave empty to use defaults
        })
      end,
    })

    use({
      "windwp/nvim-ts-autotag",
    })

    use({
      "antosha417/nvim-lsp-file-operations",
      requires = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-tree.lua",
      },
      config = function()
        require("lsp-file-operations").setup()
      end,
    })

    use({
      "kdheepak/lazygit.nvim",
      -- optional for floating window border decoration
      requires = {
        "nvim-lua/plenary.nvim",
      },
    })

    use({
      "brglng/vim-im-select",
    })
  end,
  config = {
    display = {
      open_fn = require("packer.util").float,
    },
  },
})

local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.completion.spell,
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.code_actions.eslint_d, -- Code Actionsを追加
    null_ls.builtins.diagnostics.luacheck.with({
      extra_args = { "--globals", "vim", "--globals", "use" },
    }),
  },
})

require("code_runner").setup({
  filetype = {
    java = {
      "cd $dir &&",
      "javac $fileName &&",
      "java $fileNameWithoutExt",
    },
    python = "python3 -u",
    typescript = "deno run",
    rust = {
      "cd $dir &&",
      "rustc $fileName &&",
      "$dir/$fileNameWithoutExt",
    },
    c = { "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt" },
  },
})

local highlight = {
  "RainbowRed",
  "RainbowYellow",
  "RainbowBlue",
  "RainbowOrange",
  "RainbowGreen",
  "RainbowViolet",
  "RainbowCyan",
}
local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
  vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
  vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
  vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
  vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
  vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
  vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

vim.g.rainbow_delimiters = { highlight = highlight }
require("ibl").setup({ scope = { highlight = highlight } })

hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

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
  pickers = {},
  extensions = {
    fzf = {
      fuzzy = true,                -- false will only do exact Matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = "smart_case",    -- or "ignore_case" or "respect_case"
    },
  },
})

require("nvim-treesitter.configs").setup({
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = "all",
  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = false,
  -- List of parsers to ignore installing (or "all")
  ignore_install = {},

  autotag = {
    enable = true,
  },

  highlight = {
    enable = true,
    disable = {},
  },
})

require("nvim-ts-autotag").setup()

--local treeutils = require "treeutils"
--vim.keymap.set("n", "<Leader>f", treeutils.launch_find_files)
--vim.keymap.set("n", "<Leader>g", treeutils.launch_live_grep)
--vim.keymap.set("n", "<Leader>g", treeutils.launch_live_grep)
--vim.keymap.set("n", "<Leader>g", treeutils.launch_live_grep)
