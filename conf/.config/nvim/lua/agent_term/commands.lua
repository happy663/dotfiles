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
    draft_height = config.draft.attached_height,
    fallback_target_patterns = config.draft.fallback_target_patterns,
  }
  if vim.bo[current_bufnr].buftype == "terminal" then
    focus_opts.target_bufnr = current_bufnr
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

  vim.api.nvim_create_user_command("AgentCodex", function(command)
    layouts.open_agent_codex({ args = command.args })
  end, { nargs = "*", desc = "Open Codex agent terminal" })

  vim.api.nvim_create_user_command("AgentDraftSend", function(cmd_opts)
    local success, message = draft.send_draft({
      hide_after = true,
      clear_input = not cmd_opts.bang,
    })
    if not success then
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, { bang = true, desc = "Send agent draft buffer to target terminal (! to keep terminal input)" })

  vim.api.nvim_create_user_command("AgentDraftClear", function()
    local success, message = draft.clear_draft()
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Clear agent draft buffer" })

  vim.api.nvim_create_user_command("AgentDraft", function()
    layouts.open_term_draft({ draft_height = config.draft.attached_height })
  end, { desc = "Open agent draft buffer linked to current terminal" })

  vim.keymap.set({ "n", "i", "t", "v" }, "<M-a>", toggle_draft_buffer, {
    noremap = true,
    silent = true,
    desc = "Toggle agent draft buffer",
  })

  vim.api.nvim_create_user_command("AgentDraftQuote", function()
    local l1 = vim.fn.line("'<")
    local l2 = vim.fn.line("'>")
    local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)

    draft.quote_to_draft(lines, {
      draft_height = config.draft.attached_height,
      fallback_target_patterns = config.draft.fallback_target_patterns,
    })
  end, { range = true, desc = "Quote selected text to agent draft buffer" })

  vim.keymap.set("v", "<leader>iq", ":<C-u>AgentDraftQuote<CR>", {
    noremap = true,
    silent = true,
    desc = "Quote selection to agent draft",
  })

  vim.keymap.set("v", "<leader>>", ":<C-u>AgentDraftQuote<CR>", {
    noremap = true,
    silent = true,
    desc = "Quote selection to agent draft",
  })

  vim.api.nvim_create_user_command("AgentClaude", function(command)
    layouts.open_agent_claude({ args = command.args })
  end, { nargs = "*", desc = "Open Claude agent terminal + draft buffer" })

  vim.api.nvim_create_user_command("AgentClaudeCodex", function(command)
    layouts.open_agent_claude_codex({ args = command.args })
  end, { nargs = "*", desc = "Open Claude + Codex agent terminals + draft buffer" })

  vim.keymap.set("n", "<leader>ai", ":AgentClaudeCodex<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Claude + Codex agent terminals",
  })

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

  vim.api.nvim_create_user_command("AgentClaudePair", function(command)
    layouts.open_agent_claude_pair({ args = command.args })
  end, { nargs = "*", desc = "Open two Claude agent terminals with centered input" })

  vim.keymap.set("n", "<leader>aD", ":AgentClaudePair<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Claude agent pair",
  })
end

return M
