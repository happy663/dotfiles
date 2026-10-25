-- 通常のterminalバッファ用テキストオブジェクトとプロンプト移動。
-- Agent固有の出力形式には依存せず、powerlevel10kの❯プロンプトだけを扱う。

local M = {}
local setup_done = false

function M.is_prompt_line(line)
  return line ~= nil and line:match("^❯") ~= nil
end

function M.is_info_line(line)
  return line ~= nil and line:match("│") ~= nil
end

local function trim_end(lines, start, stop)
  while stop > start and (lines[stop] or ""):match("^%s*$") do
    stop = stop - 1
  end
  return stop
end

function M.prompt_rows(lines)
  local rows = {}
  for i, line in ipairs(lines) do
    if M.is_prompt_line(line) then
      table.insert(rows, i)
    end
  end
  return rows
end

function M.jump_target(rows, lnum, direction, line_count)
  if direction > 0 then
    for _, row in ipairs(rows) do
      if row > lnum then
        return row
      end
    end
    return line_count
  end

  for i = #rows, 1, -1 do
    if rows[i] < lnum then
      return rows[i]
    end
  end
  return nil
end

function M.turn_range(lines, lnum)
  local start = nil
  for i = lnum, 1, -1 do
    if M.is_prompt_line(lines[i]) then
      start = i
      break
    end
  end
  if start == nil then
    return nil, nil
  end

  local stop = #lines
  for i = start + 1, #lines do
    if M.is_info_line(lines[i]) or M.is_prompt_line(lines[i]) then
      stop = i - 1
      break
    end
  end

  return start, trim_end(lines, start, stop)
end

local function select_turn(inner)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start, stop = M.turn_range(lines, vim.api.nvim_win_get_cursor(0)[1])
  if start == nil then
    return
  end

  if inner then
    start = start + 1
  end
  if start > stop then
    return
  end

  vim.api.nvim_win_set_cursor(0, { start, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { stop, 0 })
end

local function jump_turn(direction)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local target = M.jump_target(M.prompt_rows(lines), vim.api.nvim_win_get_cursor(0)[1], direction, #lines)
  if target ~= nil then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

local function attach(buf)
  local opts = { buffer = buf, silent = true }

  vim.keymap.set({ "o", "x" }, "it", function()
    select_turn(true)
  end, vim.tbl_extend("force", opts, { desc = "inner terminal output" }))
  vim.keymap.set({ "o", "x" }, "at", function()
    select_turn(false)
  end, vim.tbl_extend("force", opts, { desc = "around terminal output" }))
  vim.keymap.set({ "o", "x" }, "iC", function()
    select_turn(true)
  end, vim.tbl_extend("force", opts, { desc = "inner terminal turn" }))
  vim.keymap.set({ "o", "x" }, "aC", function()
    select_turn(false)
  end, vim.tbl_extend("force", opts, { desc = "around terminal turn" }))
  vim.keymap.set("n", "}", function()
    jump_turn(1)
  end, vim.tbl_extend("force", opts, { desc = "next terminal prompt" }))
  vim.keymap.set("n", "{", function()
    jump_turn(-1)
  end, vim.tbl_extend("force", opts, { desc = "prev terminal prompt" }))
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  local group = vim.api.nvim_create_augroup("terminal_textobjects", { clear = true })
  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function(ev)
      attach(ev.buf)
    end,
  })
end

return M
