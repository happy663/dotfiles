-- 別ペインの Agent 一覧と下書きを同時に開き、ペインを移動せずにプロンプトを送る。
-- ローカル宛（自分のペインの Agent）は従来どおり <M-a> の draft.lua が担当する。
local draft_buf = require("agent_term.draft_buf")
local panes = require("agent_term.panes")
local remote_send = require("agent_term.remote_send")

local M = {}

local ICONS = {
  blocked = "◐",
  idle = "✓",
  running = "●",
  error = "✕",
}
local ICON_UNKNOWN = "·"
-- running のまま一定時間更新されていないペイン。中断されて入力待ちの可能性がある。
-- 走っているのか止まっているのか判別できないので、running とは別の印にする。
local ICON_STALE = "◌"

local DRAFT_HEIGHT = 8
local LIST_MAX_HEIGHT = 10
local MAX_WIDTH = 100

-- 開いている UI の実体。閉じたら nil に戻す。
local ui = nil

local function notify(msg, level)
  vim.notify("[agent_send_to] " .. msg, level or vim.log.levels.INFO)
end

local function display_width(s)
  return vim.fn.strdisplaywidth(s)
end

local function pad(s, width)
  local diff = width - display_width(s)
  if diff <= 0 then
    return s
  end
  return s .. string.rep(" ", diff)
end

-- 一覧の各行を組み立てる。@pane-task が未生成のペインは空欄のままにする。
local function build_lines(list)
  local task_w, project_w = 0, 0
  for _, p in ipairs(list) do
    task_w = math.max(task_w, display_width(p.task))
    project_w = math.max(project_w, display_width(p.project))
  end

  local lines = {}
  for _, p in ipairs(list) do
    local icon = p.stale and ICON_STALE or (ICONS[p.status] or ICON_UNKNOWN)
    local location = ("%s:%d"):format(p.session, p.window_index)
    lines[#lines + 1] = ("%s %s  %s  %s"):format(icon, pad(p.task, task_w), pad(p.project, project_w), location)
  end
  return lines
end

local function close_win(win)
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

function M.is_open()
  return ui ~= nil and vim.api.nvim_win_is_valid(ui.draft_win)
end

function M.close()
  if not ui then
    return false, "picker is not open"
  end
  close_win(ui.list_win)
  close_win(ui.draft_win)
  ui = nil
  return true, "closed"
end

-- 一覧側のカーソル行から宛先を取り出す。
function M.selected()
  if not M.is_open() then
    return nil
  end
  if not vim.api.nvim_win_is_valid(ui.list_win) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(ui.list_win)[1]
  return ui.panes[row]
end

local function render_list(list)
  vim.bo[ui.list_buf].modifiable = true
  vim.api.nvim_buf_set_lines(ui.list_buf, 0, -1, false, build_lines(list))
  vim.bo[ui.list_buf].modifiable = false
  ui.panes = list
end

-- 一覧を取り直す。可能なら選択中のペインへカーソルを戻す。
function M.refresh()
  if not M.is_open() then
    return false, "picker is not open"
  end

  local prev = M.selected()
  local list = panes.list()
  if #list == 0 then
    return false, "送信できる Agent が見つからない"
  end

  render_list(list)

  local row = 1
  if prev then
    for i, p in ipairs(list) do
      if p.pane_id == prev.pane_id then
        row = i
        break
      end
    end
  end
  pcall(vim.api.nvim_win_set_cursor, ui.list_win, { row, 0 })
  return true, "refreshed"
end

function M.open()
  if M.is_open() then
    vim.api.nvim_set_current_win(ui.draft_win)
    vim.cmd("startinsert")
    return true, "focused existing picker"
  end

  local list = panes.list()
  if #list == 0 then
    local message = "送信できる Agent が見つからない"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local width = math.min(MAX_WIDTH, math.max(40, vim.o.columns - 8))
  local list_height = math.min(#list, LIST_MAX_HEIGHT)
  local total = (list_height + 2) + (DRAFT_HEIGHT + 2)
  local row = math.max(0, math.floor((vim.o.lines - total) / 2))
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[list_buf].buftype = "nofile"
  vim.bo[list_buf].bufhidden = "wipe"
  vim.bo[list_buf].swapfile = false

  local list_win = vim.api.nvim_open_win(list_buf, false, {
    relative = "editor",
    width = width,
    height = list_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Agents ",
    title_pos = "center",
  })
  vim.wo[list_win].cursorline = true

  local buf = draft_buf.create_input_buffer("[Agent Send To]")
  draft_buf.apply_send_keymaps(buf, {
    send = "AgentSendToSend",
    clear = "AgentSendToClear",
  })

  local draft_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = DRAFT_HEIGHT,
    row = row + list_height + 2,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Prompt ",
    title_pos = "center",
  })

  ui = {
    list_buf = list_buf,
    list_win = list_win,
    draft_buf = buf,
    draft_win = draft_win,
    panes = list,
  }

  render_list(list)
  pcall(vim.api.nvim_win_set_cursor, list_win, { 1, 0 })

  -- 一覧側は読み取り専用なので q / <Esc> で閉じられるようにする。
  -- 下書き側はキーを増やさない（<C-w> で一覧へ移り j / k で宛先を選ぶ）。
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<Cmd>AgentSendToClose<CR>", {
      buffer = list_buf,
      noremap = true,
      silent = true,
      desc = "Close agent send-to picker",
    })
  end

  vim.cmd("startinsert")
  return true, "opened"
end

-- 選択中の宛先へ下書きの内容を送る。成功したら本文だけ消し、UI は開いたまま残す。
function M.send()
  if not M.is_open() then
    local message = "picker is not open"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local content = draft_buf.read_content(ui.draft_buf)
  if content == "" then
    local message = "本文が空"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local target = M.selected()
  local ok, message = remote_send.send(target, content)
  if not ok then
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  draft_buf.clear(ui.draft_buf)

  local label = target.task ~= "" and target.task or ("%s:%d"):format(target.session, target.window_index)
  notify("送信: " .. label .. " (" .. message .. ")")
  return true, message
end

function M.clear()
  if not M.is_open() then
    return false, "picker is not open"
  end
  draft_buf.clear(ui.draft_buf)
  return true, "cleared"
end

return M
