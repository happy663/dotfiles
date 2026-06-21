return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      local base_config = {
        style = "moon",
        light_style = "day",
        terminal_colors = true,
        styles = {
          -- HACK:この項目はコメントアウトしても変化がない．よくわらない
          comments = { italic = true },
          -- HACK: 正直この項目がわからない．これを設定するとコマンドラインのItalicが無効になる
          keywords = { italic = false },
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
          }
          highlights.ColorColumn = {
            bg = "None",
          }
          highlights.CopilotSuggestion = {
            -- fg = colors.comment, -- コメントと同じ色に
            -- または特定の色を指定
            fg = colors.fg_dark,
          }
          highlights.WhichKeyNormal = {
            fg = colors.fg,
            bg = "#1f2335", -- この行を変更
          }
          highlights.Italic = {
            italic = false,
          }

          -- highlights.String = {
          --   fg = colors.fg,
          --   bg = "None",
          -- }
          highlights["@text.plain"] = { fg = colors.fg } -- Treesitterを使用している場合

          highlights["CmpItemKind" .. "Text"] = { fg = colors.blue }
          highlights["CmpItemKind" .. "Method"] = { fg = colors.green }
          highlights["CmpItemKind" .. "Function"] = { fg = colors.blue1 }
          highlights["CmpItemKind" .. "Constructor"] = { fg = colors.green1 }
          highlights["CmpItemKind" .. "Field"] = { fg = colors.orange }
          highlights["CmpItemKind" .. "Variable"] = { fg = colors.red }
          highlights["CmpItemKind" .. "Class"] = { fg = colors.yellow }
          highlights["CmpItemKind" .. "Interface"] = { fg = colors.green2 }
          highlights["CmpItemKind" .. "Module"] = { fg = colors.blue2 }
          highlights["CmpItemKind" .. "Property"] = { fg = colors.cyan }
          highlights["CmpItemKind" .. "Unit"] = { fg = colors.magenta }
          highlights["CmpItemKind" .. "Value"] = { fg = colors.orange1 }
          highlights["CmpItemKind" .. "Enum"] = { fg = colors.green3 }
          highlights["CmpItemKind" .. "Keyword"] = { fg = colors.purple }
          highlights["CmpItemKind" .. "Snippet"] = { fg = colors.red1 }
          highlights["CmpItemKind" .. "Color"] = { fg = colors.teal }
          highlights["CmpItemKind" .. "File"] = { fg = colors.blue3 }
          highlights["CmpItemKind" .. "Reference"] = { fg = colors.red2 }
          highlights["CmpItemKind" .. "Folder"] = { fg = colors.blue4 }
          highlights["CmpItemKind" .. "EnumMember"] = { fg = colors.cyan1 }
          highlights["CmpItemKind" .. "Constant"] = { fg = colors.orange2 }
          highlights["CmpItemKind" .. "Struct"] = { fg = colors.yellow1 }
          highlights["CmpItemKind" .. "Event"] = { fg = colors.red3 }
          highlights["CmpItemKind" .. "Operator"] = { fg = colors.orange3 }
          highlights["CmpItemKind" .. "TypeParameter"] = { fg = colors.yellow2 }
        end,

        cache = true,
        plugins = {
          all = package.loaded.lazy == nil,
          auto = true,
        },
      }

      local merged_config = vim.tbl_deep_extend("force", base_config, {
        transparent = true,
      })

      require("tokyonight").setup(merged_config)

      local function set_ghostty_opacity(opacity)
        local config_path = vim.fn.expand("~/.config/ghostty/config")
        local file = io.open(config_path, "r")
        if not file then
          return
        end
        local content = file:read("*a")
        file:close()
        content = content:gsub("background%-opacity = [%d%.]+", "background-opacity = " .. opacity)
        file = io.open(config_path, "w")
        if not file then
          return
        end
        file:write(content)
        file:close()
        vim.fn.system(
          [[osascript -e 'tell application "System Events" to keystroke "," using {command down, shift down}']]
        )
      end

      vim.g.tokyonight_transparent_toggle = false
      function _G.toggle_transparent()
        if vim.g.tokyonight_transparent_toggle then
          require("tokyonight").setup(vim.tbl_deep_extend("force", merged_config, {
            transparent = false,
          }))
          vim.g.tokyonight_transparent_toggle = false
          set_ghostty_opacity("1")
        else
          require("tokyonight").setup(vim.tbl_deep_extend("force", merged_config, {
            transparent = true,
          }))
          vim.g.tokyonight_transparent_toggle = true
          set_ghostty_opacity("0.8")
        end

        vim.cmd("colorscheme tokyonight")
      end

      vim.keymap.set(
        "n",
        "<leader>ta",
        ":lua toggle_transparent()<CR>",
        { noremap = true, silent = true, desc = "Toggle transparent" }
      )
    end,
  },
}
