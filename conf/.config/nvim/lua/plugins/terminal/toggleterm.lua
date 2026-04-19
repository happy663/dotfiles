return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cond = vim.g.not_in_vscode,
    config = function()
      require("toggleterm").setup({
        size = 20,
        -- open_mapping = [[<C-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        -- insert_mappings = true,
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

      local Terminal = require("toggleterm.terminal").Terminal
      local codex_count = 0
      vim.keymap.set("n", "<leader>co", function()
        codex_count = codex_count + 1
        local codex = Terminal:new({
          cmd = "codex",
          display_name = "codex-" .. codex_count,
          direction = "float",
          on_open = function(term)
            vim.keymap.set(
              "t",
              "<C-CR>",
              [[<C-\><C-n>A<CR><Esc>]],
              { buffer = term.bufnr, noremap = true, silent = true }
            )
          end,
        })
        codex:open()
      end, { desc = "Open new Codex terminal" })

      vim.keymap.set("n", "<leader>ts", ":TermSelect<CR>", { desc = "Select terminal to open" })

      -- editor insert → terminal → editor に戻った時に insert mode を復元する
      local prev_was_insert = false
      vim.keymap.set("n", [[<C-\>]], "<Cmd>ToggleTerm<CR>", { desc = "Toggle terminal from normal mode" })
      vim.keymap.set("i", [[<C-\>]], function()
        print("Toggling terminal from insert mode")
        prev_was_insert = true
        vim.cmd("ToggleTerm")
      end, { desc = "Toggle terminal from insert mode" })

      -- terminal insertモード中でも<C-\>でトグルできるようにする
      vim.keymap.set("t", [[<C-\>]], function()
        local is_toggleterm = vim.bo.filetype == "toggleterm"
        if is_toggleterm then
          vim.cmd("ToggleTerm")
          if prev_was_insert then
            prev_was_insert = false
            vim.schedule(function()
              vim.cmd("startinsert")
            end)
          end
        else
          prev_was_insert = true
          vim.cmd("ToggleTerm")
        end
      end, { desc = "Toggle terminal from terminal mode" })

      -- ターミナルモード表示: ボーダー色でInsert/Normalを区別
      local augroup = vim.api.nvim_create_augroup("ToggleTermModes", { clear = true })

      vim.api.nvim_set_hl(0, "ToggleTermInsertBorder", { fg = "#78ccc5" })
      vim.api.nvim_set_hl(0, "ToggleTermNormalBorder", { fg = "#908caa" })
      vim.api.nvim_set_hl(0, "ToggleTermVisualBorder", { fg = "#9745be" })

      vim.api.nvim_set_hl(0, "ToggleTermInsertTitle", { fg = "#78ccc5", bold = true })
      vim.api.nvim_set_hl(0, "ToggleTermNormalTitle", { fg = "#908caa", bold = true })
      vim.api.nvim_set_hl(0, "ToggleTermVisualTitle", { fg = "#9745be", bold = true })

      vim.api.nvim_create_autocmd("ModeChanged", {
        group = augroup,
        pattern = "*:t",
        callback = function()
          local win = vim.api.nvim_get_current_win()
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= "" then
            config.title = { { " I ", "ToggleTermInsertTitle" } }
            config.title_pos = "center"
            vim.api.nvim_win_set_config(win, config)
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
            config.title = { { " N ", "ToggleTermNormalTitle" } }
            config.title_pos = "center"
            vim.api.nvim_win_set_config(win, config)
            vim.wo.winhighlight = "FloatBorder:ToggleTermNormalBorder"
          end
        end,
      })

      -- ターミナルNormalモードからVisualモードに入った時
      vim.api.nvim_create_autocmd("ModeChanged", {
        group = augroup,
        pattern = "nt:*[vV\x16]",
        callback = function()
          local win = vim.api.nvim_get_current_win()
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= "" then
            config.title = { { " V ", "ToggleTermVisualTitle" } }
            config.title_pos = "center"
            vim.api.nvim_win_set_config(win, config)
            vim.wo.winhighlight = "FloatBorder:ToggleTermVisualBorder"
          end
        end,
      })
    end,
  },
}
