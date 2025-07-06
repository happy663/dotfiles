return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = true,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      explorer = {
        enabled = false,
        finder = "explorer",
        sort = { fields = { "sort" } },
        supports_live = true,
        tree = true,
        watch = true,
        diagnostics = true,
        diagnostics_open = false,
        git_status = true,
        git_status_open = false,
        git_untracked = true,
        follow_file = true,
        focus = "list",
        auto_close = false,
        jump = { close = false },
        layout = { preset = "sidebar", preview = false },

        -- to show the explorer to the right, add the below to
        -- your config under `opts.picker.sources.explorer`
        -- layout = { layout = { position = "right" } },
        formatters = {
          file = { filename_only = true },
          severity = { pos = "right" },
        },
        matcher = { sort_empty = false, fuzzy = false },
        config = function(opts)
          return require("snacks.picker.source.explorer").setup(opts)
        end,
        win = {
          list = {
            keys = {
              ["<BS>"] = "explorer_up",
              ["l"] = "confirm",
              ["h"] = "explorer_close", -- close directory
              ["a"] = "explorer_add",
              ["d"] = "explorer_del",
              ["r"] = "explorer_rename",
              ["c"] = "explorer_copy",
              ["m"] = "explorer_move",
              ["o"] = "explorer_open", -- open with system application
              ["P"] = "toggle_preview",
              ["y"] = { "explorer_yank", mode = { "n", "x" } },
              ["p"] = "explorer_paste",
              ["u"] = "explorer_update",
              ["<c-c>"] = "tcd",
              ["<leader>/"] = "picker_grep",
              ["<c-t>"] = "terminal",
              ["."] = "explorer_focus",
              ["I"] = "toggle_ignored",
              ["H"] = "toggle_hidden",
              ["Z"] = "explorer_close_all",
              ["]g"] = "explorer_git_next",
              ["[g"] = "explorer_git_prev",
              ["]d"] = "explorer_diagnostic_next",
              ["[d"] = "explorer_diagnostic_prev",
              ["]w"] = "explorer_warn_next",
              ["[w"] = "explorer_warn_prev",
              ["]e"] = "explorer_error_next",
              ["[e"] = "explorer_error_prev",
            },
          },
        },
      },
      indent = { enabled = false },
      input = { enabled = false },
      picker = { enabled = false },
      notifier = { enabled = false },
      quickfile = { enabled = false },
      scope = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
      words = { enabled = false },
    },
    keys = {
      {
        "<leader>.",
        function()
          Snacks.scratch({ ft = "markdown" })
        end,
        desc = "Markdown Scratch",
      },

      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },

      {

        "<leader>sc",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
      },
      {
        "<leader>N",
        desc = "Neovim News",
        function()
          Snacks.win({
            file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            width = 0.6,
            height = 0.6,
            wo = {
              spell = false,
              wrap = false,
              signcolumn = "yes",
              statuscolumn = " ",
              conceallevel = 3,
            },
          })
        end,
      },
    },
  },
}
