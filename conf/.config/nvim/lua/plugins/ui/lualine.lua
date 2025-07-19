return {
  {
    "nvim-lualine/lualine.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = {
      "InsertEnter",
      -- "BufEnter",
    },
    config = function()
      require("lualine").setup({
        options = {
          theme = "ayu_mirage",
        },
        winbar = {
          -- lualine_a = {
          --   { require("conf.config.nvim.lua.plugins.ui.lualine.cc-component") },
          -- },
          -- lualine_b = {
          --   { "filename", file_status = false, newfile_status = false, path = 1 },
          -- },
          -- lualine_c = {
          --   { "diff", symbols = { added = " ", modified = " ", removed = " " } },
          -- },
          -- lualine_x = { { "diagnostics", sources = { "nvim_lsp" } } },
          -- lualine_y = {
          --   { "filetype", icon_only = true },
          -- },
          -- lualine_z = {
          --   {
          --     "filename",
          --     newfile_status = true,
          --     symbols = {
          --       modified = " ",
          --       readonly = "󰌾 ",
          --     },
          --   },
          -- },
        },
        sections = {
          lualine_a = {
            { require("plugins.ui.lualine.cc-component") },
          },
          lualine_x = {
            {
              "copilot",
              cond = function()
                -- Copilotが読み込まれている場合のみ表示
                return pcall(require, "copilot")
              end,
            },
            {
              require("noice").api.statusline.mode.get,
              cond = require("noice").api.statusline.mode.has,
              color = { fg = "#ff9e64" },
            },
            {
              "cdate",
            },
            {
              "ctime",
            },
          },
        },
      })
    end,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "archibate/lualine-time",
      {
        "leisurelicht/lualine-copilot.nvim",
        lazy = true,
      },
      opt = true,
    },
  },
}
