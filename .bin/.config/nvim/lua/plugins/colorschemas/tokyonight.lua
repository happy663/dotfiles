return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      require("tokyonight").setup({
        transparent = true,
        style = "storm",
        light_style = "day",
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
          sidebars = "transparent",
          floats = "transparent",
        },
        day_brightness = 0.3,
        dim_inactive = false,
        lualine_bold = false,
        on_colors = function(colors) end,
        on_highlights = function(highlights, colors)
          highlights.Comment = {
            fg = colors.comment,
            italic = true,
          }
          highlights.CopilotSuggestion = {
            -- fg = colors.comment, -- コメントと同じ色に
            -- または特定の色を指定
            fg = colors.fg_dark,
          }
        end,

        -- hogehogehoeg
        cache = true,
        plugins = {
          all = package.loaded.lazy == nil,
          auto = true,
        },
      })
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
}


