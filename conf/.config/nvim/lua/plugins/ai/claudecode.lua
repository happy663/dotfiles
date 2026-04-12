return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  init = function()
    -- local group = vim.api.nvim_create_augroup("ClaudeCodeTerminalNormalMode", { clear = true })
    -- vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    --   group = group,
    --   callback = function(args)
    --     local bufnr = args.buf
    --     if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "terminal" then
    --       return
    --     end
    --
    --     local name = vim.api.nvim_buf_get_name(bufnr):lower()
    --     if not name:find("claude", 1, true) then
    --       return
    --     end
    --
    --     vim.schedule(function()
    --       if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
    --         return
    --       end
    --       if vim.api.nvim_get_mode().mode == "t" then
    --         vim.cmd("stopinsert")
    --       end
    --     end)
    --   end,
    --   desc = "Keep Claude terminal in terminal-normal mode on focus",
    -- })
  end,
  config = true,
  opts = {
    -- Server Configuration
    port_range = { min = 10000, max = 65535 },
    auto_start = true,
    log_level = "info", -- "trace", "debug", "info", "warn", "error"
    terminal_cmd = nil, -- Custom terminal command (default: "claude")
    -- For local installations: "~/.claude/local/claude"
    -- For native binary: use output from 'which claude'

    -- Send/Focus Behavior
    -- When true, successful sends will focus the Claude terminal if already connected
    focus_after_send = false,

    -- Selection Tracking
    track_selection = true,
    visual_demotion_delay_ms = 50,

    -- Terminal Configuration
    terminal = {
      split_side = "right", -- "left" or "right"
      split_width_percentage = 0.35,
      provider = "auto", -- "auto", "snacks", "native", "external", "none", or custom provider table
      auto_close = true,
      snacks_win_opts = {}, -- Opts to pass to `Snacks.terminal.open()` - see Floating Window section below

      -- Provider-specific options
      provider_opts = {
        -- Command for external terminal provider. Can be:
        -- 1. String with %s placeholder: "alacritty -e %s" (backward compatible)
        -- 2. String with two %s placeholders: "alacritty --working-directory %s -e %s" (cwd, command)
        -- 3. Function returning command: function(cmd, env) return "alacritty -e " .. cmd end
        external_terminal_cmd = nil,
      },
    },

    -- Diff Integration
    diff_opts = {
      layout = "vertical", -- "vertical" or "horizontal"
      open_in_new_tab = false,
      keep_terminal_focus = false, -- If true, moves focus back to terminal after diff opens
      hide_terminal_in_new_tab = false,
      -- on_new_file_reject = "keep_empty", -- "keep_empty" or "close_window"

      -- Legacy aliases (still supported):
      -- vertical_split = true,
      -- open_in_current_tab = true,
    },
  },
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    {
      "<leader>af",
      function()
        vim.cmd("ClaudeCodeFocus")
        vim.schedule(function()
          if vim.bo.buftype == "terminal" then
            local name = vim.api.nvim_buf_get_name(0):lower()
            if name:find("claude", 1, true) then
              vim.cmd("stopinsert")
            end
          end
        end)
      end,
      desc = "Focus Claude (terminal-normal mode)",
    },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>at", "<cmd>ClaudeDraftFocus<cr>", desc = "Focus Claude draft" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
