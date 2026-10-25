-- Agent terminal専用のメッセージ/ターン移動。
-- AgentPi / AgentClaude が明示的にattachしたterminalバッファだけへマップを登録する。

local M = {}
local setup_done = false
local ns_marks = vim.api.nvim_create_namespace("agent_term_message_nav_marks")

local CLAUDE_BLOCK_MARK = "^⏺"
local CLAUDE_PROMPT_MARK = "^❯"

function M.classify_marker_line(line)
  if line == nil or line == "" then
    return "assistant"
  end
  if line:match("^%s+$") then
    return "user"
  end
  return "assistant"
end

function M.neighbor(list, lnum, direction)
  if direction > 0 then
    for _, value in ipairs(list) do
      if value > lnum then
        return value
      end
    end
  else
    for i = #list, 1, -1 do
      if list[i] < lnum then
        return list[i]
      end
    end
  end
  return nil
end

function M.jump_target(list, lnum, direction, line_count)
  local target = M.neighbor(list, lnum, direction)
  if target ~= nil then
    return target
  end
  if direction > 0 then
    return line_count
  end
  return nil
end

function M.block_range(list, lnum, line_count)
  if #list == 0 then
    return nil, nil
  end

  local start = nil
  for i = #list, 1, -1 do
    if list[i] <= lnum then
      start = list[i]
      break
    end
  end
  start = start or list[1]

  local stop = (M.neighbor(list, start, 1) or (line_count + 1)) - 1
  return start, math.min(stop, line_count)
end

function M.trim_block_end(lines, start, stop)
  while stop > start and (lines[stop] or ""):match("^%s*$") do
    stop = stop - 1
  end
  return stop
end

local function buffer_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function current_line()
  return vim.api.nvim_win_get_cursor(0)[1]
end

local function select_lines(start, stop)
  if start == nil or stop == nil or start > stop then
    return
  end
  vim.api.nvim_win_set_cursor(0, { start, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { stop, 0 })
end

local function claude_rows(lines, pattern)
  local rows = {}
  for i, line in ipairs(lines) do
    if line:match(pattern) then
      table.insert(rows, i)
    end
  end
  return rows
end

local function claude_select(kind, inner)
  local lines = buffer_lines(0)
  local pattern = kind == "message" and CLAUDE_BLOCK_MARK or CLAUDE_PROMPT_MARK
  local rows = claude_rows(lines, pattern)
  local start, stop = M.block_range(rows, current_line(), #lines)
  if start == nil then
    return
  end

  if kind == "message" then
    local next_prompt = M.neighbor(claude_rows(lines, CLAUDE_PROMPT_MARK), start, 1)
    if next_prompt ~= nil then
      stop = math.min(stop, next_prompt - 1)
    end
  end

  stop = M.trim_block_end(lines, start, stop)
  if inner then
    start = start + 1
  end
  select_lines(start, stop)
end

local function claude_jump(kind, direction)
  local lines = buffer_lines(0)
  local pattern = kind == "message" and CLAUDE_BLOCK_MARK or CLAUDE_PROMPT_MARK
  local target = M.jump_target(claude_rows(lines, pattern), current_line(), direction, #lines)
  if target ~= nil then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

local function pi_data(buf)
  local lines = buffer_lines(buf)
  local data = { all = {}, users = {}, responses = {}, lines = lines }
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns_marks, 0, -1, {})) do
    local row = mark[2] + 1
    table.insert(data.all, row)
    if M.classify_marker_line(lines[row]) == "user" then
      table.insert(data.users, row)
    else
      table.insert(data.responses, row)
    end
  end
  return data
end

local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

local function pi_select(kind, inner)
  local data = pi_data(0)
  local rows = kind == "message" and data.all or data.users
  local start, stop = M.block_range(rows, current_line(), #data.lines)
  if start == nil then
    return
  end
  if kind == "message" and not contains(data.responses, start) then
    return
  end

  stop = M.trim_block_end(data.lines, start, stop)
  if inner then
    start = start + 1
  end
  select_lines(start, stop)
end

local function pi_jump(kind, direction)
  local data = pi_data(0)
  local rows = kind == "message" and data.responses or data.users
  local target = M.jump_target(rows, current_line(), direction, #data.lines)
  if target ~= nil then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

local function attach_keymaps(buf, kind)
  local opts = { buffer = buf, silent = true }
  local select_impl = kind == "pi" and pi_select or claude_select
  local jump_impl = kind == "pi" and pi_jump or claude_jump

  vim.keymap.set({ "o", "x" }, "ic", function()
    select_impl("message", true)
  end, vim.tbl_extend("force", opts, { desc = "inner agent message" }))
  vim.keymap.set({ "o", "x" }, "ac", function()
    select_impl("message", false)
  end, vim.tbl_extend("force", opts, { desc = "around agent message" }))
  vim.keymap.set({ "o", "x" }, "iC", function()
    select_impl("turn", true)
  end, vim.tbl_extend("force", opts, { desc = "inner agent turn" }))
  vim.keymap.set({ "o", "x" }, "aC", function()
    select_impl("turn", false)
  end, vim.tbl_extend("force", opts, { desc = "around agent turn" }))
  vim.keymap.set("n", "]c", function()
    jump_impl("message", 1)
  end, vim.tbl_extend("force", opts, { desc = "next agent message" }))
  vim.keymap.set("n", "[c", function()
    jump_impl("message", -1)
  end, vim.tbl_extend("force", opts, { desc = "prev agent message" }))
  vim.keymap.set("n", "}", function()
    jump_impl("turn", 1)
  end, vim.tbl_extend("force", opts, { desc = "next agent turn" }))
  vim.keymap.set("n", "{", function()
    jump_impl("turn", -1)
  end, vim.tbl_extend("force", opts, { desc = "prev agent turn" }))
end

function M.attach(buf, kind)
  M.setup()

  if kind ~= "pi" and kind ~= "claude" then
    error("unsupported agent message navigation kind: " .. tostring(kind))
  end
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
    error("agent message navigation requires a terminal buffer")
  end

  vim.b[buf].agent_message_nav_kind = kind
  attach_keymaps(buf, kind)
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  local group = vim.api.nvim_create_augroup("agent_term_message_nav", { clear = true })
  vim.api.nvim_create_autocmd("TermRequest", {
    group = group,
    callback = function(ev)
      local sequence = ev.data and ev.data.sequence or ""
      if sequence:match("^\27%]133;A") == nil then
        return
      end
      local lnum = ev.data.cursor and ev.data.cursor[1]
      if lnum ~= nil and lnum >= 1 then
        pcall(vim.api.nvim_buf_set_extmark, ev.buf, ns_marks, lnum - 1, 0, {})
      end
    end,
  })
end

return M
