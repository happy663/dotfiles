return {
  {
    "nvim-lualine/lualine.nvim",
    config = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      opt = true,
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
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
    dependencies = "nvim-tree/nvim-web-devicons",
  },
  {
    "akinsho/bufferline.nvim",
    config = true,
    dependencies = "kyazdani42/nvim-web-devicons",
    version = "*",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = true,
  },
  {
    "folke/noice.nvim",
    config = function()
      require("noice").setup({
        view = {
          mini = {
            position = "bottom-right",
          },
        },
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          hover = {
            enabled = false,
          },
        },
        routes = {
          {
            filter = {
              event = "msg_show", -- msg_showイベントのメッセージを対象
              min_height = 1, -- 最小高さが1行のメッセージを対象
            },
            view = "mini", -- 上で定義したカスタムビューにルーティング
          },
          {
            filter = {
              event = "notify",
              find = "No information available",
            },
            opts = { skip = true },
          },
          {
            filter = {
              event = "notify",
              find = "method textDocument/hover is not supported by any of the servers registered for the current buffer",
            },
            opts = { skip = true },
          },
          {
            filter = {
              event = "notify",
              find = "# Config Change Detected. Reloading...",
            },
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
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
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
      ts_update()
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = "all",
        sync_install = false,
        auto_install = false,
        ignore_install = {},
        autotag = {
          enable = true,
        },
        highlight = {
          enable = true,
          disable = {},
        },
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-tree.lua",
    },
    config = true,
  },
}