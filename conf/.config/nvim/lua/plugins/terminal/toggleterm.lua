return {
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
        auto_scroll = false, -- automatically scroll to the bottom on terminal output
      })

      -- ターミナルモード表示: ボーダー色でInsert/Normalを区別
      local augroup = vim.api.nvim_create_augroup("ToggleTermModes", { clear = true })

      vim.api.nvim_set_hl(0, "ToggleTermInsertBorder", { fg = "#78ccc5" })
      vim.api.nvim_set_hl(0, "ToggleTermNormalBorder", { fg = "#908caa" })

      vim.api.nvim_create_autocmd("ModeChanged", {
        group = augroup,
        pattern = "*:t",
        callback = function()
          local win = vim.api.nvim_get_current_win()
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= "" then
            vim.wo.winhighlight = "FloatBorder:ToggleTermInsertBorder"
          end
        end,
      })

      vim.api.nvim_create_autocmd("ModeChanged", {
        group = augroup,
        pattern = "*:nt",
        callback = function()
          local win = vim.api.nvim_get_current_win()
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= "" then
            vim.wo.winhighlight = "FloatBorder:ToggleTermNormalBorder"
          end
        end,
      })
    end,
  },
}
