local config = require("agent_term.config")
local state = require("agent_term.state")
local terminals = require("agent_term.terminals")

local M = {}
M.defaults = {
  target_pattern = config.defaults.draft_target_pattern,
}

local tab_bufnr_registry = {}
local setup_done = false

local function notify(msg, level)
  vim.notify("[claude_input] " .. msg, level or vim.log.levels.INFO)
end

local function trim_trailing_empty_lines(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  return lines
end

local function resize_current_draft_window(default_height)
  local height = state.get_draft_height(default_height)
  if height then
    vim.cmd("resize " .. tostring(height))
  end
end

local function save_visible_draft_height(bufnr)
  if not state.is_valid_buf(bufnr) then
    return
  end

  local current_tabpage = vim.api.nvim_get_current_tabpage()
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if
      vim.api.nvim_win_is_valid(winid)
      and vim.api.nvim_win_get_tabpage(winid) == current_tabpage
      and vim.api.nvim_win_get_buf(winid) == bufnr
    then
      state.set_draft_height(vim.api.nvim_win_get_height(winid))
      return
    end
  end
end

local function focus_existing_draft(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("startinsert")
      return true
    end
  end
  return false
end

local function resolve_target_terminal_bufnr(target_pattern)
  local target_bufnr = state.get_target_terminal_bufnr()
  if state.is_valid_buf(target_bufnr) then
    return target_bufnr
  end

  local terminal = terminals.find_terminal_by_pattern(target_pattern, false)
  if terminal and state.is_valid_buf(terminal.bufnr) then
    return terminal.bufnr
  end

  return nil
end

local function resolve_target_terminal_winid(target_bufnr, target_pattern)
  local current_tab_wins = vim.api.nvim_tabpage_list_wins(0)

  local function find_winid_for(bufnr)
    if not state.is_valid_buf(bufnr) then
      return nil
    end
    for _, winid in ipairs(current_tab_wins) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
        return winid
      end
    end
    return nil
  end

  local winid = find_winid_for(target_bufnr)
  if winid then
    return winid
  end

  if type(target_pattern) == "string" and target_pattern ~= "" then
    local terminal = terminals.find_terminal_by_pattern(target_pattern, false)
    if terminal and state.is_valid_buf(terminal.bufnr) then
      return find_winid_for(terminal.bufnr)
    end
  end

  return nil
end

local function open_split_below_target(target_bufnr, target_pattern, draft_height)
  local target_winid = resolve_target_terminal_winid(target_bufnr, target_pattern)
  if target_winid then
    vim.api.nvim_set_current_win(target_winid)
    vim.cmd("belowright split")
    resize_current_draft_window(draft_height)

    local draft_winid = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(target_winid) then
      local term_bufnr = vim.api.nvim_win_get_buf(target_winid)
      if state.is_valid_buf(term_bufnr) then
        local line_count = vim.api.nvim_buf_line_count(term_bufnr)
        pcall(vim.api.nvim_win_set_cursor, target_winid, { line_count, 0 })
      end
    end
    if vim.api.nvim_win_is_valid(draft_winid) then
      vim.api.nvim_set_current_win(draft_winid)
    end

    return true
  end

  vim.cmd("botright split")
  resize_current_draft_window(draft_height)
  return false
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

  local target_pattern = opts.target_pattern or state.get_target_pattern(M.defaults.target_pattern)
  local draft_bufnr = state.get_draft_bufnr()

  if draft_bufnr then
    if focus_existing_draft(draft_bufnr) then
      return true, "Focused existing draft buffer"
    end

    local target_bufnr = opts.claude_bufnr
    if not state.is_valid_buf(target_bufnr) then
      target_bufnr = state.get_target_terminal_bufnr()
    end

    local via_target = open_split_below_target(target_bufnr, target_pattern, opts.draft_height)
    vim.api.nvim_win_set_buf(0, draft_bufnr)
    resize_current_draft_window(opts.draft_height)
    vim.wo.winfixheight = true
    vim.cmd("startinsert")
    if not via_target then
      notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
    end
    return true, "Opened existing draft buffer"
  end

  local terminal_bufnr = opts.claude_bufnr
  if not state.is_valid_buf(terminal_bufnr) then
    terminal_bufnr = resolve_target_terminal_bufnr(target_pattern)
  end
  if not state.is_valid_buf(terminal_bufnr) then
    return false, "Target terminal not found for draft buffer"
  end

  local via_target = open_split_below_target(terminal_bufnr, target_pattern, opts.draft_height)
  M.open_input_buffer({
    claude_bufnr = terminal_bufnr,
    target_pattern = target_pattern,
    draft_height = opts.draft_height,
  })
  if not via_target then
    notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
  end
  return true, "Opened draft buffer"
end

function M.open_input_buffer(opts)
  opts = opts or {}

  local bufnr = state.get_draft_bufnr()
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "[Claude Input]")
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "markdown"
    vim.bo[bufnr].modifiable = true
    ensure_buffer_keymaps(bufnr)
    vim.b[bufnr].claude_input = true
  end

  state.set_draft_bufnr(bufnr)
  tab_bufnr_registry[vim.api.nvim_get_current_tabpage()] = bufnr
  if opts.claude_bufnr and state.is_valid_buf(opts.claude_bufnr) then
    state.set_target_terminal_bufnr(opts.claude_bufnr)
  end
  state.set_target_pattern(opts.target_pattern)

  vim.api.nvim_win_set_buf(0, bufnr)
  resize_current_draft_window(opts.draft_height)
  vim.wo.winfixheight = true
  vim.cmd("startinsert")

  return bufnr
end

function M.clear_draft()
  local bufnr = state.get_draft_bufnr()
  if not bufnr then
    return false, "Claude draft buffer not found"
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  return true, "Claude draft buffer cleared"
end

function M.hide()
  local bufnr = state.get_draft_bufnr()
  if not bufnr then
    return false, "Claude draft buffer not found"
  end

  local windows = vim.fn.win_findbuf(bufnr)
  if #windows == 0 then
    return false, "Claude draft buffer is not visible"
  end

  save_visible_draft_height(bufnr)

  local prev_winid = state.get_prev_winid()
  local fallback_winid
  local target_bufnr = state.get_target_terminal_bufnr()
  if state.is_valid_buf(target_bufnr) then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == target_bufnr then
        fallback_winid = winid
        break
      end
    end
  end

  for _, winid in ipairs(windows) do
    if vim.api.nvim_win_is_valid(winid) then
      pcall(vim.api.nvim_win_close, winid, false)
    end
  end

  local function try_focus(winid)
    if winid and vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      return true
    end
    return false
  end

  if not try_focus(prev_winid) then
    try_focus(fallback_winid)
  end

  return true, "Claude draft buffer hidden"
end

function M.send_draft(opts)
  opts = opts or {}
  local hide_after
  if opts.hide_after == nil then
    hide_after = true
  else
    hide_after = opts.hide_after and true or false
  end

  local draft_bufnr = state.get_draft_bufnr()
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
  local target_bufnr = state.get_target_terminal_bufnr()
  local target_pattern = state.get_target_pattern(M.defaults.target_pattern)
  if state.is_valid_buf(target_bufnr) then
    for index, term in ipairs(terminals.get_all_terminals()) do
      if term.bufnr == target_bufnr then
        target_index = index
        break
      end
    end
  end

  local target = target_index or target_pattern

  if hide_after then
    M.hide()
    vim.cmd("redraw")
    vim.wait(250)
  end

  local success, message =
    terminals.send_command(target, content, { add_newline = true, exclude_current = false, paste = true })
  if not success then
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  M.clear_draft()

  local focused_terminal = false
  if state.is_valid_buf(target_bufnr) then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == target_bufnr then
        vim.api.nvim_set_current_win(winid)
        focused_terminal = true
        break
      end
    end
  end
  if focused_terminal then
    vim.cmd("startinsert")
  end

  return true, message
end

function M.quote_to_draft(lines, opts)
  opts = opts or {}

  local quoted = {}
  for _, line in ipairs(lines) do
    table.insert(quoted, "> " .. line)
  end

  local draft_bufnr = state.get_draft_bufnr()
  local need_open = draft_bufnr == nil or #vim.fn.win_findbuf(draft_bufnr) == 0

  if need_open then
    local success, message = M.focus_or_open({
      draft_height = opts.draft_height,
      target_pattern = opts.target_pattern,
      claude_bufnr = opts.claude_bufnr,
    })
    if not success then
      return false, message
    end
    draft_bufnr = state.get_draft_bufnr()
    if not draft_bufnr then
      return false, "Failed to create draft buffer"
    end
  end

  local existing = vim.api.nvim_buf_get_lines(draft_bufnr, 0, -1, false)
  local has_content = not (#existing == 0 or (#existing == 1 and existing[1] == ""))

  local to_append = {}
  if has_content then
    table.insert(to_append, "")
  end
  for _, q in ipairs(quoted) do
    table.insert(to_append, q)
  end
  table.insert(to_append, "")

  if has_content then
    vim.api.nvim_buf_set_lines(draft_bufnr, -1, -1, false, to_append)
  else
    vim.api.nvim_buf_set_lines(draft_bufnr, 0, -1, false, to_append)
  end

  if not need_open then
    for _, winid in ipairs(vim.fn.win_findbuf(draft_bufnr)) do
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_set_current_win(winid)
        break
      end
    end
  end
  local line_count = vim.api.nvim_buf_line_count(draft_bufnr)
  vim.api.nvim_win_set_cursor(0, { line_count, 0 })
  vim.cmd("startinsert|normal! $")

  return true, "Quoted " .. #quoted .. " lines to draft"
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  local group = vim.api.nvim_create_augroup("ClaudeInputTabCleanup", { clear = true })

  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      local live_bufnrs = {}
      for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
        local ok, bufnr = pcall(vim.api.nvim_tabpage_get_var, tabpage, "claude_input_bufnr")
        if ok and state.is_valid_buf(bufnr) then
          live_bufnrs[bufnr] = true
        end
      end

      for tabpage, bufnr in pairs(tab_bufnr_registry) do
        if not vim.api.nvim_tabpage_is_valid(tabpage) then
          tab_bufnr_registry[tabpage] = nil
          if state.is_valid_buf(bufnr) and not live_bufnrs[bufnr] then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
        end
      end
    end,
  })
end

return M
