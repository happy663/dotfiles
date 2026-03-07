-- claude_input.lua
-- Claude Code向け入力バッファの作成と送信を管理するモジュール

local M = {}
M.defaults = {
  target_pattern = "claude",
}

local function is_valid_buf(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local function notify(msg, level)
  vim.notify("[claude_input] " .. msg, level or vim.log.levels.INFO)
end

local function get_draft_bufnr()
  if is_valid_buf(vim.t.claude_input_bufnr) then
    return vim.t.claude_input_bufnr
  end
  return nil
end

local function trim_trailing_empty_lines(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  return lines
end

local function focus_existing_draft(bufnr)
  local windows = vim.fn.win_findbuf(bufnr)
  for _, winid in ipairs(windows) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("startinsert")
      return true
    end
  end
  return false
end

local function resolve_target_terminal_bufnr(target_pattern)
  if is_valid_buf(vim.t.claude_terminal_bufnr) and vim.bo[vim.t.claude_terminal_bufnr].buftype == "terminal" then
    return vim.t.claude_terminal_bufnr
  end

  local bridge_ok, terminal_bridge = pcall(require, "terminal_bridge")
  if not bridge_ok then
    return nil
  end

  local terminal = terminal_bridge.find_terminal_by_pattern(target_pattern, false)
  if terminal and is_valid_buf(terminal.bufnr) then
    return terminal.bufnr
  end

  return nil
end

local function ensure_buffer_keymaps(bufnr)
  vim.keymap.set("n", "<C-CR>", "<Cmd>ClaudeDraftSend<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Send draft to Claude",
  })
  vim.keymap.set("i", "<C-CR>", "<Esc><Cmd>ClaudeDraftSend<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Send draft to Claude",
  })
  vim.keymap.set("n", "<leader>ic", "<Cmd>ClaudeDraftClear<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Clear Claude draft buffer",
  })
  vim.keymap.set("n", "<leader>is", "<Cmd>ClaudeDraftSend<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Send Claude draft buffer",
  })
end

function M.focus_or_open(opts)
  opts = opts or {}

  local draft_bufnr = get_draft_bufnr()
  if draft_bufnr then
    if focus_existing_draft(draft_bufnr) then
      return true, "Focused existing draft buffer"
    end
    vim.cmd("belowright split")
    if type(opts.draft_height) == "number" and opts.draft_height > 0 then
      vim.cmd("resize " .. tostring(opts.draft_height))
    end
    vim.api.nvim_win_set_buf(0, draft_bufnr)
    vim.cmd("startinsert")
    return true, "Opened existing draft buffer"
  end

  local target_pattern = opts.target_pattern or vim.t.claude_input_target_pattern or M.defaults.target_pattern
  local terminal_bufnr = opts.claude_bufnr
  if not is_valid_buf(terminal_bufnr) then
    terminal_bufnr = resolve_target_terminal_bufnr(target_pattern)
  end
  if not is_valid_buf(terminal_bufnr) then
    return false, "Target terminal not found for draft buffer"
  end

  vim.cmd("belowright split")
  if type(opts.draft_height) == "number" and opts.draft_height > 0 then
    vim.cmd("resize " .. tostring(opts.draft_height))
  end
  M.open_input_buffer({
    claude_bufnr = terminal_bufnr,
    target_pattern = target_pattern,
  })
  return true, "Opened draft buffer"
end

function M.open_input_buffer(opts)
  opts = opts or {}

  local bufnr = get_draft_bufnr()
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "markdown"
    vim.bo[bufnr].modifiable = true
    ensure_buffer_keymaps(bufnr)
  end

  vim.t.claude_input_bufnr = bufnr
  if opts.claude_bufnr and is_valid_buf(opts.claude_bufnr) then
    vim.t.claude_terminal_bufnr = opts.claude_bufnr
  end
  if type(opts.target_pattern) == "string" and opts.target_pattern ~= "" then
    vim.t.claude_input_target_pattern = opts.target_pattern
  end

  vim.api.nvim_win_set_buf(0, bufnr)
  vim.cmd("startinsert")

  return bufnr
end

function M.clear_draft()
  local bufnr = get_draft_bufnr()
  if not bufnr then
    return false, "Claude draft buffer not found"
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  return true, "Claude draft buffer cleared"
end

function M.send_draft()
  local bridge_ok, terminal_bridge = pcall(require, "terminal_bridge")
  if not bridge_ok then
    local message = "terminal_bridge module not found"
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  local draft_bufnr = get_draft_bufnr()
  if not draft_bufnr then
    local message = "Claude draft buffer not found"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local lines = vim.api.nvim_buf_get_lines(draft_bufnr, 0, -1, false)
  trim_trailing_empty_lines(lines)

  local content = table.concat(lines, "\n")
  if content == "" then
    local message = "Draft is empty"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local target_index
  local claude_bufnr = vim.t.claude_terminal_bufnr
  local target_pattern = vim.t.claude_input_target_pattern or M.defaults.target_pattern
  if is_valid_buf(claude_bufnr) then
    local terminals = terminal_bridge.get_all_terminals()
    for index, term in ipairs(terminals) do
      if term.bufnr == claude_bufnr then
        target_index = index
        break
      end
    end
  end

  local target = target_index or target_pattern
  local success, message =
    terminal_bridge.send_command(target, content, { add_newline = true, exclude_current = false })
  if not success then
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  notify("Sent draft to Claude", vim.log.levels.INFO)
  return true, message
end

return M
