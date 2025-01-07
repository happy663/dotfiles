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
}
