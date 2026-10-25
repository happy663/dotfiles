-- 端末バッファ内のメッセージ/ターン移動とテキストオブジェクト
--
-- Claude Code と pi で同じキーを使えるよう、バッファ内容からバックエンドを判定して振り分ける。
--
--   cli-claude : Claude Code の行頭マーカー（⏺ = 応答ブロック, ❯ = プロンプト）
--   osc133     : OSC 133 セマンティックプロンプトを出すもの（pi など）
--                pi はユーザーメッセージ先頭行を背景色で塗るため、
--                「空白のみ・非空」の行をユーザー入力とみなす
--
-- マーカー行の種別判定は TermRequest の到着時ではなく利用時に行う。
-- 到着時点では行の中身がまだ書き込まれておらず、判別を誤るため。

local M = {}

local ns_marks = vim.api.nvim_create_namespace("terminal_message_nav_marks")

local CLAUDE_BLOCK_MARK = "^⏺"
local CLAUDE_PROMPT_MARK = "^❯"

-- 純粋関数（テスト対象） ----------------------------------------------------

--- OSC 133 のマーカー行の種別を返す
--- @param line string|nil
--- @return "user"|"assistant"
function M.classify_marker_line(line)
  if line == nil or line == "" then
    return "assistant"
  end
  if line:match("^%s+$") then
    return "user"
  end
  return "assistant"
end

--- 昇順リストから dir 方向の隣の要素を返す
--- @param list number[]
--- @param lnum number
--- @param dir 1|-1
--- @return number|nil
function M.neighbor(list, lnum, dir)
  if dir > 0 then
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

--- lnum が属するブロックの開始行と終了行を返す
--- @param list number[] 昇順のマーカー行
--- @param lnum number
--- @param line_count number
--- @return number|nil start
--- @return number|nil stop
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
  if stop > line_count then
    stop = line_count
  end

  return start, stop
end

--- ジャンプ先を決める
--- 前方に次のマーカーが無ければ最新の出力（最終行）へ送る
--- @param list number[] 昇順のマーカー行
--- @param lnum number 現在行
--- @param dir 1|-1
--- @param line_count number
--- @return number|nil
function M.jump_target(list, lnum, dir, line_count)
  local target = M.neighbor(list, lnum, dir)
  if target ~= nil then
    return target
  end
  if dir > 0 then
    return line_count
  end
  return nil
end

--- ブロック末尾の空行・空白行を落とす
--- @param lines string[]
--- @param start number
--- @param stop number
--- @return number
function M.trim_block_end(lines, start, stop)
  while stop > start do
    local line = lines[stop]
    if line ~= nil and line:match("^%s*$") == nil then
      break
    end
    stop = stop - 1
  end
  return stop
end

--- バックエンド判定
--- Claude の行頭マーカーがあれば Claude を優先する（既存挙動を変えないため）
--- @param has_claude_marker boolean
--- @param has_osc133_mark boolean
--- @return "cli-claude"|"osc133"|nil
function M.detect_backend(has_claude_marker, has_osc133_mark)
  if has_claude_marker then
    return "cli-claude"
  end
  if has_osc133_mark then
    return "osc133"
  end
  return nil
end

-- バッファ操作 --------------------------------------------------------------

local function buffer_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function line_matches(line, pattern)
  return line ~= nil and line:match(pattern) ~= nil
end

local function has_claude_marker(buf)
  for _, line in ipairs(buffer_lines(buf)) do
    if line_matches(line, CLAUDE_BLOCK_MARK) then
      return true
    end
  end
  return false
end

local function osc133_rows(buf)
  local rows = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns_marks, 0, -1, {})) do
    table.insert(rows, mark[2] + 1)
  end
  return rows
end

--- 全マーカー行と、そのうちユーザー入力の行を返す
local function osc133_lists(buf)
  local lines = buffer_lines(buf)
  local all, users = {}, {}
  for _, row in ipairs(osc133_rows(buf)) do
    table.insert(all, row)
    if M.classify_marker_line(lines[row]) == "user" then
      table.insert(users, row)
    end
  end
  return all, users, lines
end

local function current_backend(buf)
  return M.detect_backend(has_claude_marker(buf), #osc133_rows(buf) > 0)
end

local function current_line()
  return vim.api.nvim_win_get_cursor(0)[1]
end

local function select_lines(start, stop)
  if start == nil or stop == nil or start > stop then
    return false
  end
  vim.api.nvim_win_set_cursor(0, { start, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { stop, 0 })
  return true
end

-- Claude Code バックエンド --------------------------------------------------

local function claude_block_bounds(lnum, line_count)
  local lines = buffer_lines(0)
  local block_start = nil
  for i = lnum, 1, -1 do
    local line = lines[i]
    if line_matches(line, CLAUDE_BLOCK_MARK) then
      block_start = i
      break
    end
    if line_matches(line, CLAUDE_PROMPT_MARK) and i < lnum then
      return nil, nil
    end
  end
  if block_start == nil then
    return nil, nil
  end

  local block_end = line_count
  for i = block_start + 1, line_count do
    local line = lines[i]
    if line_matches(line, CLAUDE_BLOCK_MARK) or line_matches(line, CLAUDE_PROMPT_MARK) then
      block_end = i - 1
      break
    end
  end

  return block_start, block_end
end

local function claude_turn_bounds(lnum, line_count)
  local lines = buffer_lines(0)
  local turn_start = nil
  for i = lnum, 1, -1 do
    if line_matches(lines[i], CLAUDE_PROMPT_MARK) then
      turn_start = i
      break
    end
  end
  if turn_start == nil then
    return nil, nil
  end

  local turn_end = line_count
  for i = turn_start + 1, line_count do
    if line_matches(lines[i], CLAUDE_PROMPT_MARK) then
      turn_end = i - 1
      break
    end
  end

  return turn_start, turn_end
end

local function claude_select(kind, inner)
  local lnum = current_line()
  local line_count = vim.api.nvim_buf_line_count(0)
  local start, stop
  if kind == "message" then
    start, stop = claude_block_bounds(lnum, line_count)
  else
    start, stop = claude_turn_bounds(lnum, line_count)
  end
  if start == nil then
    return
  end

  stop = M.trim_block_end(buffer_lines(0), start, stop)
  if inner then
    start = start + 1
  end
  select_lines(start, stop)
end

local function claude_jump(kind, forward)
  local lines = buffer_lines(0)
  local pattern = kind == "message" and CLAUDE_BLOCK_MARK or CLAUDE_PROMPT_MARK
  local lnum = current_line()
  local line_count = vim.api.nvim_buf_line_count(0)

  if forward then
    for i = lnum + 1, line_count do
      if line_matches(lines[i], pattern) then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        return
      end
    end
    -- 前方に次のマーカーが無ければ最新の出力へ
    vim.api.nvim_win_set_cursor(0, { line_count, 0 })
  else
    for i = lnum - 1, 1, -1 do
      if line_matches(lines[i], pattern) then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        return
      end
    end
  end
end

-- OSC 133 バックエンド ------------------------------------------------------

--- 応答ブロックのマーカー行のみを抽出する
local function osc133_response_rows(all, users)
  local user_set = {}
  for _, row in ipairs(users) do
    user_set[row] = true
  end

  local rows = {}
  for _, row in ipairs(all) do
    if not user_set[row] then
      table.insert(rows, row)
    end
  end
  return rows
end

local function osc133_select(kind, inner)
  local buf = vim.api.nvim_get_current_buf()
  local all, users, lines = osc133_lists(buf)
  local lnum = current_line()
  local line_count = vim.api.nvim_buf_line_count(buf)

  local list
  if kind == "message" then
    list = osc133_response_rows(all, users)
    -- 応答ブロック専用（Claude の ⏺ と同じ意味に揃える）
    local start, stop = M.block_range(all, lnum, line_count)
    if start == nil then
      return
    end
    local is_response = false
    for _, row in ipairs(list) do
      if row == start then
        is_response = true
        break
      end
    end
    if not is_response then
      return
    end
  else
    list = #users > 0 and users or all
  end

  local start, stop = M.block_range(list, lnum, line_count)
  if start == nil then
    return
  end

  stop = M.trim_block_end(lines, start, stop)
  if inner then
    start = start + 1
  end
  select_lines(start, stop)
end

local function osc133_jump(kind, forward)
  local buf = vim.api.nvim_get_current_buf()
  local all, users = osc133_lists(buf)

  local list
  if kind == "message" then
    list = osc133_response_rows(all, users)
  else
    -- プロンプト行が判別できないテーマでも移動できるようにフォールバックする
    list = #users > 0 and users or all
  end

  local target = M.jump_target(list, current_line(), forward and 1 or -1, vim.api.nvim_buf_line_count(buf))
  if target ~= nil then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

-- 公開 API ------------------------------------------------------------------

local function select_message(inner)
  local buf = vim.api.nvim_get_current_buf()
  if current_backend(buf) == "cli-claude" then
    claude_select("message", inner)
  else
    osc133_select("message", inner)
  end
end

local function select_turn(inner)
  local buf = vim.api.nvim_get_current_buf()
  if current_backend(buf) == "cli-claude" then
    claude_select("turn", inner)
  else
    osc133_select("turn", inner)
  end
end

local function jump_message(forward)
  local buf = vim.api.nvim_get_current_buf()
  if current_backend(buf) == "cli-claude" then
    claude_jump("message", forward)
  else
    osc133_jump("message", forward)
  end
end

local function jump_turn(forward)
  local buf = vim.api.nvim_get_current_buf()
  if current_backend(buf) == "cli-claude" then
    claude_jump("turn", forward)
  else
    osc133_jump("turn", forward)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("TermRequest", {
    callback = function(ev)
      local sequence = ev.data and ev.data.sequence or ""
      if sequence:match("^\27%]133;A") == nil then
        return
      end
      local lnum = ev.data.cursor and ev.data.cursor[1]
      if lnum == nil or lnum < 1 then
        return
      end
      pcall(vim.api.nvim_buf_set_extmark, ev.buf, ns_marks, lnum - 1, 0, {})
    end,
  })

  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
      local buf_opts = { buffer = ev.buf, silent = true }
      -- テキストオブジェクト
      vim.keymap.set({ "o", "x" }, "ic", function()
        select_message(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "inner agent message" }))
      vim.keymap.set({ "o", "x" }, "ac", function()
        select_message(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "around agent message" }))
      vim.keymap.set({ "o", "x" }, "iC", function()
        select_turn(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "inner agent turn" }))
      vim.keymap.set({ "o", "x" }, "aC", function()
        select_turn(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "around agent turn" }))
      -- ジャンプ
      vim.keymap.set("n", "]c", function()
        jump_message(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "next agent message" }))
      vim.keymap.set("n", "[c", function()
        jump_message(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "prev agent message" }))
      vim.keymap.set("n", "}", function()
        jump_turn(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "next agent turn" }))
      vim.keymap.set("n", "{", function()
        jump_turn(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "prev agent turn" }))
    end,
  })
end

return M
