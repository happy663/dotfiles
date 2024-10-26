return {
  {
    "nvim-lualine/lualine.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("lualine").setup({
        options = {
          theme = "ayu_mirage",
        },
        sections = {
          lualine_x = {
            {
              require("noice").api.statusline.mode.get,
              cond = require("noice").api.statusline.mode.has,
              color = { fg = "#ff9e64" },
            },
          },
        },
      })
    end,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      opt = true,
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    cond = vim.g.not_in_vscode,
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = {},
        },
        update_focused_file = {
          enable = true,
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          highlight_opened_files = "name",
          icons = {
            glyphs = {
              git = {
                unstaged = "!",
                renamed = "»",
                untracked = "?",
                deleted = "✘",
                staged = "✓",
                unmerged = "",
                ignored = "◌",
              },
            },
          },
        },
        filters = {
          git_ignored = false,
          dotfiles = false,
          custom = {
            "__pycache__",
            ".git",
          },
        },
      })
    end,
    dependencies = "nvim-tree/nvim-web-devicons",
  },
  {
    "akinsho/bufferline.nvim",
    dependencies = "kyazdani42/nvim-web-devicons",
    version = "*",
    cond = vim.g.not_in_vscode,
    config = function()
      local bufferline = require("bufferline")
      bufferline.setup({
        options = {
          numbers = "none",
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = false,
          diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          style_preset = bufferline.style_preset.no_italic,
        },
      })
      vim.api.nvim_set_keymap("n", "<leader>bco", ":BufferLineCloseOthers<CR>", { noremap = true, silent = true })
    end,
  },
  {
    -- "lukas-reineke/indent-blankline.nvim",
    -- main = "ibl",
    -- cond = vim.g.not_in_vscode,
    -- config = true,
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "UIEnter" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },
  {
    "folke/noice.nvim",
    cond = vim.g.not_in_vscode,
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
          bottom_search = false,
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
    cond = vim.g.not_in_vscode,
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<C-\>]],
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
        highlight = {
          enable = true,
          disable = function(lang)
            -- if lang == "latex" then
            --   return true
            -- end
            return vim.g.vscode
          end,
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ia"] = "@assignment.inner",
              ["aa"] = "@assignment.outer",
              ["lh"] = "@assignment.lhs",
              ["rh"] = "@assignment.rhs",
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
              ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
            },
            selection_modes = {
              ["@parameter.outer"] = "v", -- charwise
              ["@function.outer"] = "V", -- linewise
              ["@class.outer"] = "<c-v>", -- blockwise
            },
            include_surrounding_whitespace = true,
          },
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
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "mvllow/modes.nvim",
    version = "v0.2.0",
    config = true,
    cond = function()
      return not vim.g.vscode
    end,
  },
  {
    "brenoprata10/nvim-highlight-colors",
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "nvimdev/dashboard-nvim",
    cond = vim.g.not_in_vscode,
    event = "VimEnter",
    config = function()
      require("dashboard").setup({})
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
  {
    "petertriho/nvim-scrollbar",
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "kevinhwang91/nvim-hlslens",
    cond = vim.g.not_in_vscode,
    config = true,
  },
  {
    "subnut/nvim-ghost.nvim",
    init = function()
      vim.g.nvim_ghost_autostart = 0
    end,
    cond = vim.g.not_in_vscode,
    config = function()
      vim.api.nvim_create_augroup("nvim_ghost_user_autocommands", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = { "*github.com", "*zenn.dev", "*qiita.com" },
        group = "nvim_ghost_user_autocommands",
        callback = function()
          vim.opt.filetype = "markdown"
        end,
      })
    end,
  },
  {
    "ramilito/winbar.nvim",
    event = "VimEnter", -- Alternatively, BufReadPre if we don't care about the empty file when starting with 'nvim'
    cond = vim.g.not_in_vscode,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("winbar").setup({
        -- your configuration comes here, for example:
        icons = true,
        diagnostics = true,
        buf_modified = true,
        buf_modified_symbol = "M",
        -- or use an icon
        -- buf_modified_symbol = "●"
        dim_inactive = {
          enabled = false,
          highlight = "WinbarNC",
          icons = true, -- whether to dim the icons
          name = true, -- whether to dim the name
        },
      })
    end,
  },
  {
    "rapan931/lasterisk.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.keymap.set("n", "*", function()
        require("lasterisk").search()
        require("hlslens").start()
        vim.cmd("set hlsearch")
        vim.cmd("HlSearchLensEnable")
        vim.g.highlight_on = true
      end)
      vim.keymap.set({ "n", "x" }, "g*", function()
        require("lasterisk").search({ is_whole = false })
        require("hlslens").start()
        vim.cmd("set hlsearch")
        vim.cmd("HlSearchLensEnable")
        vim.g.highlight_on = true
      end)
    end,
  },
  {
    "nvchad/showkeys",
    cond = vim.g.not_in_vscode,
    cmd = "ShowkeysToggle",
    opts = {
      timeout = 1,
      maxkeys = 5,
      -- more opts
    },
  },
}
