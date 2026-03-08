return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  init = function()
    local group = vim.api.nvim_create_augroup("ClaudeCodeTerminalNormalMode", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      group = group,
      callback = function(args)
        local bufnr = args.buf
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "terminal" then
          return
        end

        local name = vim.api.nvim_buf_get_name(bufnr):lower()
        if not name:find("claude", 1, true) then
          return
        end

        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
            return
          end
          if vim.api.nvim_get_mode().mode == "t" then
            vim.cmd("stopinsert")
          end
        end)
      end,
      desc = "Keep Claude terminal in terminal-normal mode on focus",
    })
  end,
  config = true,
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
