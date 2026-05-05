local config = require("agent_term.config")
local draft = require("agent_term.draft")
local layouts = require("agent_term.layouts")
local state = require("agent_term.state")
local terminals = require("agent_term.terminals")

local M = {}
local setup_done = false

local function find_draft_winid()
  local draft_bufnr = state.get_draft_bufnr()
  if not draft_bufnr then
    return nil
  end

  for _, winid in ipairs(vim.fn.win_findbuf(draft_bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      return winid
    end
  end

  return nil
end

local function toggle_draft_buffer()
  local current_winid = vim.api.nvim_get_current_win()
  local draft_winid = find_draft_winid()

  if draft_winid and draft_winid == current_winid then
    draft.hide()
    return
  end

  state.set_prev_winid(current_winid)

  if draft_winid then
    vim.api.nvim_set_current_win(draft_winid)
    vim.cmd("startinsert")
    return
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local focus_opts = {
    draft_height = config.defaults.draft_height,
    target_pattern = config.defaults.draft_target_pattern,
  }
  if vim.bo[current_bufnr].buftype == "terminal" then
    focus_opts.claude_bufnr = current_bufnr
    state.set_target_terminal_bufnr(current_bufnr)
  end

  local success, message = draft.focus_or_open(focus_opts)
  if not success then
    vim.notify(message, vim.log.levels.WARN)
  end
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  draft.setup()

  vim.api.nvim_create_user_command("CodexTerm", function(command)
    layouts.open_codex_term({ args = command.args })
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("ClaudeDraftSend", function()
    local success, message = draft.send_draft({ hide_after = true })
    if not success then
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, { desc = "Send draft buffer to Claude terminal" })

  vim.api.nvim_create_user_command("ClaudeDraftClear", function()
    local success, message = draft.clear_draft()
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Clear Claude draft buffer" })

  vim.api.nvim_create_user_command("TermDraft", function()
    layouts.open_term_draft({ draft_height = config.defaults.draft_height })
  end, { desc = "Open draft buffer linked to current terminal" })

  vim.keymap.set({ "n", "i", "t", "v" }, "<M-a>", toggle_draft_buffer, {
    noremap = true,
    silent = true,
    desc = "Toggle Claude draft buffer",
  })

  vim.api.nvim_create_user_command("ClaudeDraftQuote", function()
    local l1 = vim.fn.line("'<")
    local l2 = vim.fn.line("'>")
    local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)

    draft.quote_to_draft(lines, {
      draft_height = config.defaults.draft_height,
      target_pattern = config.defaults.draft_target_pattern,
    })
  end, { range = true, desc = "Quote selected text to Claude draft buffer" })

  vim.keymap.set("v", "<leader>iq", ":<C-u>ClaudeDraftQuote<CR>", {
    noremap = true,
    silent = true,
    desc = "Quote selection to Claude draft",
  })

  vim.api.nvim_create_user_command("ClaudeAI", function(command)
    layouts.open_claude_ai({ args = command.args })
  end, { nargs = "*", desc = "Open Claude Code + Claude draft buffer" })

  vim.api.nvim_create_user_command("DualAI", function()
    layouts.open_dual_ai()
  end, { desc = "Open Claude + Codex + Claude draft buffer" })

  vim.keymap.set("n", "<leader>ai", ":DualAI<CR>", { noremap = true, silent = true, desc = "Open Claude Code + Codex" })

  vim.api.nvim_create_user_command("TermList", function()
    local terms = terminals.get_all_terminals()
    if #terms == 0 then
      vim.notify("No terminal buffers found", vim.log.levels.WARN)
      return
    end

    print("Terminal buffers:")
    for i, term in ipairs(terms) do
      print(string.format("  [%d] bufnr=%d, name=%s", i, term.bufnr, term.name))
    end
  end, { desc = "List all terminal buffers" })

  vim.api.nvim_create_user_command("TermSend", function(cmd_opts)
    local args = vim.split(cmd_opts.args, " ", { plain = true })
    if #args < 2 then
      vim.notify("Usage: TermSend <index> <command>", vim.log.levels.ERROR)
      return
    end

    local target = tonumber(args[1])
    if not target then
      vim.notify("Invalid target index: " .. args[1], vim.log.levels.ERROR)
      return
    end

    local command = table.concat(vim.list_slice(args, 2), " ")
    local success, message = terminals.send_command(target, command)
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, { nargs = "+", desc = "Send command to terminal by index" })

  vim.api.nvim_create_user_command("DualClaude", function(command)
    layouts.open_dual_claude({ args = command.args })
  end, { nargs = "*", desc = "Open dual Claude terminals with centered input" })

  vim.keymap.set("n", "<leader>aD", ":DualClaude<CR>", {
    noremap = true,
    silent = true,
    desc = "Open DualClaude",
  })
end

return M
