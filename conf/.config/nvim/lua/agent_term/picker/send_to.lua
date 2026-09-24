-- 別ペインの Agent 一覧と下書きを同時に開き、ペインを移動せずにプロンプトを送る。
-- ローカル宛（自分のペインの Agent）は従来どおり <M-a> の draft.lua が担当する。
--
-- 右側にプレビューを出す（issue #318）。内容は送信先と一致させ、取得は preview.lua が行う。
-- プレビューにはフォーカスを移さず、下書き/一覧側のキーから遠隔で操作する（Telescope と同じ）。
-- 最下部から離れている間はプレビューを凍結する（P1）。タイトルを Preview (paused) にして、
-- 5秒ごとの自動更新が読書位置を飛ばさないようにする。
local config = require("agent_term.config")
local draft_buf = require("agent_term.draft_buf")
local layout = require("agent_term.picker.layout")
local panes = require("agent_term.picker.panes")
local preview = require("agent_term.picker.preview")
local remote_send = require("agent_term.picker.remote_send")

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

-- 状態の色は tmux.conf の pane-border-format と揃える。同じ概念を tmux の枠と
-- この一覧の両方に出すので、色が違うと別物に見えてしまう。
-- default = true なので、好みで上書きしたい場合はユーザー側の定義が優先される。
local HL = {
  blocked = "AgentSendToBlocked",
  idle = "AgentSendToIdle",
  running = "AgentSendToRunning",
  error = "AgentSendToError",
  stale = "AgentSendToStale",
  unknown = "AgentSendToUnknown",
  dim = "AgentSendToDim",
}

local function define_highlights()
  local hl = vim.api.nvim_set_hl
  hl(0, HL.blocked, { fg = "#e0af68", default = true })
  hl(0, HL.idle, { fg = "#7aa2f7", default = true })
  hl(0, HL.running, { fg = "#9ece6a", default = true })
  hl(0, HL.error, { fg = "#f7768e", default = true })
  hl(0, HL.stale, { fg = "#565f89", default = true })
  hl(0, HL.unknown, { link = "Comment", default = true })
  hl(0, HL.dim, { link = "Comment", default = true })
end

define_highlights()

-- カラースキームを変えるとハイライトが消えるので張り直す。
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("AgentSendToHighlights", { clear = true }),
  callback = define_highlights,
})

local NS = vim.api.nvim_create_namespace("agent_send_to")

local function status_hl(p)
  if p.stale then
    return HL.stale
  end
  return HL[p.status] or HL.unknown
end

-- 開いている UI の実体。閉じたら nil に戻す。
local ui = nil

-- プレビューの状態（issue #318）。
-- paused のときは取得も再描画もしない。自動更新で読書位置が飛ばないようにするため。
local preview_paused = false
-- 連続失敗回数。failure_threshold に達するまでは前回の内容を保つ。
local preview_failures = 0
-- 最後に描画した宛先。一覧の再ソートでカーソル行だけが動いた場合と、
-- 本当に宛先が変わった場合を区別するために持つ。
local preview_pane_id = nil
local preview_last_lines = nil
local preview_debounce_timer = nil

-- ピッカーを開いている間、一覧を一定間隔で自動で取り直すタイマー。
-- 下書きを書いている間に相手の状態や並びが変わっても追いかけられるようにするためのもので、
-- 開いたら開始・閉じたら停止する。手動の AgentSendToRefresh と併用する。
local REFRESH_INTERVAL_MS = config.send_to.refresh_interval_ms
local auto_refresh_timer = nil

local function stop_auto_refresh()
  if auto_refresh_timer then
    vim.fn.timer_stop(auto_refresh_timer)
    auto_refresh_timer = nil
  end
end

local function start_auto_refresh()
  stop_auto_refresh()
  if not REFRESH_INTERVAL_MS or REFRESH_INTERVAL_MS <= 0 then
    return
  end
  auto_refresh_timer = vim.fn.timer_start(REFRESH_INTERVAL_MS, function()
    -- close 以外の経路で UI が消えていたら、タイマーも止める。
    if not M.is_open() then
      stop_auto_refresh()
      return
    end
    M.refresh()
  end, { ["repeat"] = -1 })
end

local function stop_preview_debounce()
  if preview_debounce_timer then
    vim.fn.timer_stop(preview_debounce_timer)
    preview_debounce_timer = nil
  end
end

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

-- 表示幅で切り詰める。切った印に … を付ける。
-- 一覧は「カーソル行 = エージェント」で対応しているので、行が窓幅を超えて
-- 折り返すと選択がずれる。ここで窓幅に収めておく。
local function truncate_to_width(s, width)
  if width <= 0 then
    return ""
  end
  if display_width(s) <= width then
    return s
  end

  local out = ""
  local used = 0
  for _, char in ipairs(vim.fn.split(s, "\\zs")) do
    local char_width = display_width(char)
    if used + char_width > width - 1 then
      break
    end
    out = out .. char
    used = used + char_width
  end
  return out .. "…"
end

-- 一覧の各行を組み立てる。@pane-task が未生成のペインは空欄のままにする。
-- 行の文字列と、アイコン/プロジェクト以降のハイライト範囲を組み立てる。
-- 範囲はバイト位置で持つ（アイコンがマルチバイトなので文字数では合わない）。
local function build_lines(list, width)
  local task_w, project_w = 0, 0
  for _, p in ipairs(list) do
    task_w = math.max(task_w, display_width(p.task))
    project_w = math.max(project_w, display_width(p.project))
  end

  local lines, marks = {}, {}
  for row, p in ipairs(list) do
    local icon = p.stale and ICON_STALE or (ICONS[p.status] or ICON_UNKNOWN)
    local task = pad(p.task, task_w)
    local project = pad(p.project, project_w)
    local location = ("%s:%d"):format(p.session, p.window_index)

    -- 幅が足りないときは行末から落ちる（位置、プロジェクト名の順）。
    -- タイトルは先頭にあるので最後まで残る。
    local line = truncate_to_width(("%s %s  %s  %s"):format(icon, task, project, location), width)
    lines[#lines + 1] = line

    -- アイコンは状態の色、リポジトリ名と位置は淡く。タイトルは既定色のまま目立たせる。
    local icon_end = #icon
    local dim_start = icon_end + 1 + #task + 2
    marks[#marks + 1] = { row = row - 1, from = 0, to = icon_end, hl = status_hl(p) }
    if dim_start < #line then
      marks[#marks + 1] = { row = row - 1, from = dim_start, to = -1, hl = HL.dim }
    end
  end
  return lines, marks
end

local function close_win(win)
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

function M.is_open()
  return ui ~= nil and vim.api.nvim_win_is_valid(ui.draft_win)
end

local function wipe_buf(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
  end
end

-- 一覧と下書きの寸法。比率と最小幅は config.send_to.preview から取る。
local function calc_layout(list_count)
  local pc = config.send_to.preview
  return layout.calculate({
    columns = vim.o.columns,
    lines = vim.o.lines,
    list_count = list_count,
    width_ratio = pc.width_ratio,
    ratio = pc.ratio,
    min_preview_width = pc.min_preview_width,
    min_preview_height = pc.min_preview_height,
    min_prompt_width = pc.min_prompt_width,
    min_list_width = pc.min_list_width,
    height_ratio = pc.height_ratio,
    draft_height = pc.draft_height,
  })
end

local function preview_window()
  if ui and ui.preview_win and vim.api.nvim_win_is_valid(ui.preview_win) then
    return ui.preview_win
  end
  return nil
end

-- 凍結中と失敗中はタイトルで示す。本文だけでは気づけないため。
local function preview_title()
  local pc = config.send_to.preview
  if preview_failures >= pc.failure_threshold then
    return " Preview (!) "
  end
  if preview_paused then
    return " Preview (paused) "
  end
  return " Preview "
end

local function preview_win_config(l)
  return {
    relative = "editor",
    width = l.preview_width,
    height = l.preview_height,
    row = l.preview_row,
    col = l.preview_col,
    style = "minimal",
    border = "rounded",
    title = preview_title(),
    title_pos = "center",
    -- フォーカスは下書きに固定する。スクロールは nvim_win_call で遠隔から行う。
    focusable = false,
  }
end

local function apply_preview_options(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local pc = config.send_to.preview
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = pc.wrap and true or false
  if pc.wrap then
    -- 折り返したとき、継続行を字下げと記号で区別する。
    vim.wo[win].breakindent = true
    vim.wo[win].showbreak = "↳ "
    vim.wo[win].list = false
  else
    -- nowrap では右端が切れる。切れている行に印を出す。
    vim.wo[win].list = true
    vim.wo[win].listchars = "extends:›,precedes:‹"
  end
end

-- ui.layout に従ってプレビューウィンドウを作り直す/動かす。表示できない幅なら閉じる。
local function apply_preview_layout()
  if not ui or not ui.layout then
    return
  end

  local l = ui.layout
  if not l.preview_visible then
    if preview_window() then
      close_win(ui.preview_win)
      ui.preview_win = nil
    end
    return
  end

  if preview_window() then
    vim.api.nvim_win_set_config(ui.preview_win, preview_win_config(l))
  else
    ui.preview_win = vim.api.nvim_open_win(ui.preview_buf, false, preview_win_config(l))
  end
  apply_preview_options(ui.preview_win)
end

-- 凍結/失敗の状態をタイトルへ反映する。nvim_win_set_config は部分更新できないので、
-- タイトルを変えるときも ui.layout からウィンドウ設定ごと張り直す。
local function sync_preview_window()
  apply_preview_layout()
end

-- nvim_buf_set_lines は改行を含む要素を受け付けない（"item contains newlines" で例外になる）。
-- 取得元の出力やエラー本文に改行が混ざっていても描画が死なないよう、行に分解してから渡す。
-- エラー本文が複数行（Lua の traceback など）の場合は、そのまま複数行として見せる。
local function normalize_lines(lines)
  local out = {}
  for _, line in ipairs(lines) do
    local text = tostring(line):gsub("\r", "")
    if text:find("\n", 1, true) then
      for _, part in ipairs(vim.split(text, "\n", { plain = true })) do
        out[#out + 1] = part
      end
    else
      out[#out + 1] = text
    end
  end
  return out
end

local function render_preview(lines)
  if not ui.preview_buf or not vim.api.nvim_buf_is_valid(ui.preview_buf) then
    return false
  end

  local normalized = normalize_lines(lines)
  vim.bo[ui.preview_buf].modifiable = true
  local ok, err = pcall(vim.api.nvim_buf_set_lines, ui.preview_buf, 0, -1, false, normalized)
  vim.bo[ui.preview_buf].modifiable = false
  if not ok then
    -- ここで例外を投げると、選択変更や tick のコールバックが中断されて
    -- 以降プレビューが固まる。描画できないことは知らせて処理は続ける。
    notify("プレビューを描画できない: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  preview_last_lines = normalized
  return true
end

-- 追従中は末尾を見せる。プレビューはフォーカスされないので nvim_win_call で行う。
local function scroll_preview_to_bottom()
  local win = preview_window()
  if not win then
    return
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! G")
  end)
end

-- 最下部の行が見えているか。ここに戻ったら凍結を解除する。
local function preview_at_bottom()
  local win = preview_window()
  if not win then
    return true
  end
  return vim.api.nvim_win_call(win, function()
    return vim.fn.line("w$") >= vim.api.nvim_buf_line_count(0)
  end)
end

-- 選択中の宛先の内容を取り直して描き直す。凍結中は何もしない（force で無視できる）。
local function update_preview_impl(force)
  local target = M.selected()
  if not target then
    return false, "宛先が選択されていない"
  end

  local lines, err = preview.fetch(target)
  if not lines then
    preview_failures = preview_failures + 1
    -- 1回だけの失敗は一時的なことが多いので、前回の内容を保って黙ってやり過ごす。
    if preview_failures >= config.send_to.preview.failure_threshold or force then
      -- 理由は複数行になり得る（Lua の traceback など）。render_preview 側で行に分解する。
      render_preview({ "プレビューを取得できない:", tostring(err) })
    end
    preview_pane_id = target.pane_id
    sync_preview_window()
    return false, err
  end

  preview_failures = 0
  preview_pane_id = target.pane_id
  render_preview(#lines == 0 and { "出力なし" } or lines)
  scroll_preview_to_bottom()
  sync_preview_window()
  return true
end

-- 取得や描画で予期しない例外が出ても、呼び出し元（選択変更・tick のコールバック）を
-- 巻き込んでプレビューが固まらないようにする。固まると原因も見えなくなるため。
local function update_preview(force)
  if not M.is_open() or not ui.layout or not ui.layout.preview_visible then
    return false, "preview is not available"
  end
  if preview_paused and not force then
    return false, "preview is paused"
  end

  local ok, succeeded, message = pcall(update_preview_impl, force)
  if not ok then
    local reason = tostring(succeeded)
    notify("プレビューを更新できない: " .. reason, vim.log.levels.WARN)
    return false, reason
  end
  return succeeded, message
end

-- 選択変更は即座に反映したいが、C-n/C-p の連打で毎回 RPC すると重いので少し待つ。
local function schedule_preview_update()
  if not M.is_open() then
    return
  end
  stop_preview_debounce()

  local ms = config.send_to.preview.debounce_ms
  if not ms or ms <= 0 then
    update_preview(true)
    return
  end

  preview_debounce_timer = vim.fn.timer_start(ms, function()
    preview_debounce_timer = nil
    if not M.is_open() then
      return
    end
    update_preview(true)
  end)
end

-- 一覧のカーソルが動いたときの処理。再ソートで行だけが動いた場合は宛先が変わって
-- いないので、凍結を解除しない（読書中のプレビューを飛ばさないため）。
local function on_list_cursor_moved()
  if not M.is_open() then
    return
  end
  local target = M.selected()
  if not target or target.pane_id == preview_pane_id then
    return
  end
  preview_paused = false
  schedule_preview_update()
end

-- プレビューのスクロール。最下部に着いたら凍結を解除し、離れたら凍結する。
local function preview_scroll(command)
  local win = preview_window()
  if not win then
    return false, "preview is not available"
  end

  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! " .. command)
  end)

  if preview_at_bottom() then
    if preview_paused then
      preview_paused = false
      update_preview(true)
    end
  else
    preview_paused = true
  end
  sync_preview_window()
  return true
end

-- 横スクロールの刻み。'sidescroll' はグローバルオプションでウィンドウ単位にできないため、
-- キーにカウントを付けて桁を進める。
local PREVIEW_HSCROLL = 10

-- 横スクロール。凍結の対象外（縦位置は動かないため）。
local function preview_scroll_horizontal(command)
  local win = preview_window()
  if not win then
    return false, "preview is not available"
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! " .. command)
  end)
  return true
end

local function cmp_visible()
  local ok, cmp = pcall(require, "cmp")
  return ok and cmp.visible()
end

local function cmp_scroll(delta)
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.scroll_docs(delta)
  end
end

-- 挿入モードの <C-u> / <C-d>。編集のキー（行頭まで削除・インデント）だが、
-- このバッファではプレビューのスクロールに割り当てる（Telescope と同じ）。
-- 補完メニューが出ているときだけ cmp のドキュメントスクロールを優先する。
--
-- cmp は InsertEnter でバッファローカルの挿入モードマップを張り直すため、
-- 開いたときに一度張るだけでは <C-d> が cmp に上書きされる。
-- set_preview_keymaps と InsertEnter の両方から呼んで、常にこちらを勝たせる。
local function set_preview_insert_keymaps(target_buf)
  local opts = { buffer = target_buf, noremap = true, silent = true }

  vim.keymap.set("i", "<C-u>", function()
    if cmp_visible() then
      cmp_scroll(4)
    else
      M.preview_scroll_up()
    end
  end, vim.tbl_extend("force", opts, { desc = "Scroll the agent preview up" }))

  vim.keymap.set("i", "<C-d>", function()
    if cmp_visible() then
      cmp_scroll(-4)
    else
      M.preview_scroll_down()
    end
  end, vim.tbl_extend("force", opts, { desc = "Scroll the agent preview down" }))
end

-- 下書きと一覧の両方に張る。
local function set_preview_keymaps(target_buf)
  local opts = { buffer = target_buf, noremap = true, silent = true }

  vim.keymap.set(
    "n",
    "<C-u>",
    "<Cmd>AgentSendToPreviewUp<CR>",
    vim.tbl_extend("force", opts, { desc = "Scroll the agent preview up" })
  )
  vim.keymap.set(
    "n",
    "<C-d>",
    "<Cmd>AgentSendToPreviewDown<CR>",
    vim.tbl_extend("force", opts, { desc = "Scroll the agent preview down" })
  )
  vim.keymap.set(
    "n",
    "G",
    "<Cmd>AgentSendToPreviewFollow<CR>",
    vim.tbl_extend("force", opts, { desc = "Follow the agent preview" })
  )
  vim.keymap.set(
    "n",
    "zh",
    "<Cmd>AgentSendToPreviewLeft<CR>",
    vim.tbl_extend("force", opts, { desc = "Scroll the agent preview left" })
  )
  vim.keymap.set(
    "n",
    "zl",
    "<Cmd>AgentSendToPreviewRight<CR>",
    vim.tbl_extend("force", opts, { desc = "Scroll the agent preview right" })
  )

  set_preview_insert_keymaps(target_buf)
end

-- 閉じたらバッファも捨てる。残すと次に開くとき同名バッファで nvim_buf_set_name が
-- 失敗し、開けないまま浮きウィンドウが漏れる。書きかけを残さないのは意図でもある
-- （閉じて開き直したとき、古い本文が新しい宛先に向いている状態を作らない）。
function M.close()
  if not ui then
    stop_auto_refresh()
    stop_preview_debounce()
    return false, "picker is not open"
  end
  stop_auto_refresh()
  stop_preview_debounce()
  close_win(ui.preview_win)
  close_win(ui.list_win)
  close_win(ui.draft_win)
  wipe_buf(ui.preview_buf)
  wipe_buf(ui.draft_buf)
  wipe_buf(ui.list_buf)
  ui = nil
  preview_paused = false
  preview_failures = 0
  preview_pane_id = nil
  preview_last_lines = nil
  return true, "closed"
end

-- 下書きから離れずに宛先を1つ動かす。端まで来たら反対側へ回り込む。
local function move_selection(delta)
  if not M.is_open() or not vim.api.nvim_win_is_valid(ui.list_win) then
    return false
  end
  local count = #ui.panes
  if count == 0 then
    return false
  end
  local row = vim.api.nvim_win_get_cursor(ui.list_win)[1]
  row = ((row - 1 + delta) % count) + 1
  pcall(vim.api.nvim_win_set_cursor, ui.list_win, { row, 0 })
  -- CursorMoved はイベントループに戻るまで発火しないので、ここで直接知らせる。
  -- 後から発火する CursorMoved は、宛先が同じなので on_list_cursor_moved が無視する。
  on_list_cursor_moved()
  return true
end

function M.select_next()
  return move_selection(1)
end

function M.select_prev()
  return move_selection(-1)
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
  local lines, marks = build_lines(list, (ui.layout and ui.layout.list_width) or vim.o.columns)
  vim.bo[ui.list_buf].modifiable = true
  vim.api.nvim_buf_set_lines(ui.list_buf, 0, -1, false, lines)
  vim.bo[ui.list_buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(ui.list_buf, NS, 0, -1)
  for _, m in ipairs(marks) do
    local opts = { hl_group = m.hl }
    if m.to >= 0 then
      opts.end_col = m.to
    else
      opts.end_row = m.row + 1
      opts.end_col = 0
    end
    pcall(vim.api.nvim_buf_set_extmark, ui.list_buf, NS, m.row, m.from, opts)
  end

  ui.panes = list
end

-- Agent 数が変わったら一覧の高さを変え、Prompt とプレビューも追従させる。
-- バッファだけ更新すると、増えた行が開いた時点のウィンドウ高さの外に隠れてしまう。
local function update_layout(list_count)
  local l = calc_layout(list_count)
  ui.layout = l

  vim.api.nvim_win_set_config(ui.list_win, {
    relative = "editor",
    width = l.list_width,
    height = l.list_height,
    row = l.list_row,
    col = l.list_col,
    style = "minimal",
    border = "rounded",
    title = " Agents ",
    title_pos = "center",
  })
  vim.api.nvim_win_set_config(ui.draft_win, {
    relative = "editor",
    width = l.draft_width,
    height = l.draft_height,
    row = l.draft_row,
    col = l.draft_col,
    style = "minimal",
    border = "rounded",
    title = " Prompt ",
    title_pos = "center",
  })

  apply_preview_layout()
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
  update_layout(#list)

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

  -- 凍結中は取得しない。一覧の再描画（他の agent の状態）は続ける。
  if not preview_paused then
    update_preview()
  end
  return true, "refreshed"
end

function M.open()
  if M.is_open() then
    vim.api.nvim_set_current_win(ui.draft_win)
    return true, "focused existing picker"
  end

  local list = panes.list()
  if #list == 0 then
    local message = "送信できる Agent が見つからない"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local l = calc_layout(#list)

  -- 前回の残骸が居ると nvim_buf_set_name が失敗するので、先に片付ける。
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b):match("%[Agent Send To%]$") then
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end

  stop_preview_debounce()
  preview_paused = false
  preview_failures = 0
  preview_pane_id = nil
  preview_last_lines = nil

  -- ウィンドウより先にバッファを用意する。作成に失敗しても浮きウィンドウが残らない。
  local buf = draft_buf.create_input_buffer("[Agent Send To]")
  draft_buf.apply_send_keymaps(buf, {
    send = "AgentSendToSend",
    clear = "AgentSendToClear",
  })

  -- 宛先の移動。挿入モードは <C-n> / <C-p> が補完（cmp.lua）、<C-j> が skkeleton、
  -- <Tab> が copilot に取られているため、ノーマルモードだけに張る。
  -- このバッファ限定なので、ローカル下書き（draft.lua）側の割り当てとは衝突しない。
  vim.keymap.set("n", "<C-n>", "<Cmd>AgentSendToNext<CR>", {
    buffer = buf,
    noremap = true,
    silent = true,
    desc = "Select next agent",
  })
  vim.keymap.set("n", "<C-p>", "<Cmd>AgentSendToPrev<CR>", {
    buffer = buf,
    noremap = true,
    silent = true,
    desc = "Select previous agent",
  })

  -- 送るのではなく自分が行きたいとき。<C-CR> が送信なので <S-CR> を移動に当てる。
  -- tmux.conf の extended-keys on / csi-u により両者は区別して届く。
  for _, mode in ipairs({ "n", "i" }) do
    vim.keymap.set(mode, "<S-CR>", "<Cmd>AgentSendToJump<CR>", {
      buffer = buf,
      noremap = true,
      silent = true,
      desc = "Jump to the selected agent pane",
    })
  end

  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[list_buf].buftype = "nofile"
  vim.bo[list_buf].bufhidden = "wipe"
  vim.bo[list_buf].swapfile = false

  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].swapfile = false
  vim.bo[preview_buf].modifiable = false

  local list_win = vim.api.nvim_open_win(list_buf, false, {
    relative = "editor",
    width = l.list_width,
    height = l.list_height,
    row = l.list_row,
    col = l.list_col,
    style = "minimal",
    border = "rounded",
    title = " Agents ",
    title_pos = "center",
  })
  vim.wo[list_win].cursorline = true
  -- 行が窓幅を超えて折り返すと、カーソル行とエージェントの対応が崩れる。
  -- build_lines 側で幅に収めているが、念のため折り返しも切っておく。
  vim.wo[list_win].wrap = false
  vim.wo[list_win].list = true
  vim.wo[list_win].listchars = "extends:›,precedes:‹"

  local draft_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = l.draft_width,
    height = l.draft_height,
    row = l.draft_row,
    col = l.draft_col,
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
    preview_buf = preview_buf,
    preview_win = nil,
    layout = l,
    panes = list,
  }

  apply_preview_layout()

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

  -- 一覧側からも移動できるようにする。行を選んで Enter は素直な操作なので
  -- <CR> も同じ動きにする。
  for _, key in ipairs({ "<CR>", "<S-CR>" }) do
    vim.keymap.set("n", key, "<Cmd>AgentSendToJump<CR>", {
      buffer = list_buf,
      noremap = true,
      silent = true,
      desc = "Jump to the selected agent pane",
    })
  end

  -- プレビューの操作は下書きと一覧の両方から行えるようにする。
  set_preview_keymaps(buf)
  set_preview_keymaps(list_buf)

  -- cmp が InsertEnter で挿入モードのマップを張り直すため、こちらを後から再設定する
  -- （autocmd は登録順に走るので、起動時に登録される cmp より後に実行される）。
  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = buf,
    callback = function()
      set_preview_insert_keymaps(buf)
    end,
  })

  -- 挿入モードでは始めない。開いた直後は宛先を選ぶ場面が多く、<C-n> / <C-p> が
  -- ノーマルモードの割り当てなのでそのまま押せる。本文を書くときに i を押す。
  start_auto_refresh()
  update_preview(true)

  -- 再ソートでカーソル行だけが動いた場合と、本当に宛先が変わった場合を区別するため、
  -- イベント側で宛先を突き合わせる（on_list_cursor_moved）。
  -- 初回の取得より後で登録する。先に張ると、開いた直後の set_cursor で
  -- 余分な取得が走る。
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = list_buf,
    callback = on_list_cursor_moved,
  })

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

-- 選択中のペインへ移動する。送るのではなく自分が行きたいとき用。
-- ペイン、ウィンドウ、セッションの順に指定する。pane_id だけでは別ウィンドウや
-- 別セッションにいる場合に切り替わらないため。
function M.jump()
  if not M.is_open() then
    local message = "picker is not open"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local target = M.selected()
  if not target then
    local message = "宛先が選択されていない"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  if not panes.exists(target.pane_id) then
    local message = "ペインが存在しない: " .. target.pane_id
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  -- 移動すると下書きは破棄される（close でバッファごと捨てるため）。
  -- 黙って消すと書いた内容を失ったことに気づけないので、その場合だけ知らせる。
  local had_draft = draft_buf.read_content(ui.draft_buf) ~= ""
  local label = target.task ~= "" and target.task or ("%s:%d"):format(target.session, target.window_index)

  M.close()

  for _, args in ipairs({
    { "select-pane", "-t", target.pane_id },
    { "select-window", "-t", target.pane_id },
    { "switch-client", "-t", target.pane_id },
  }) do
    local cmd = { "tmux" }
    vim.list_extend(cmd, args)
    vim.system(cmd):wait()
  end

  if had_draft then
    notify("移動: " .. label .. "（書きかけの下書きは破棄した）", vim.log.levels.WARN)
  end
  return true, "jumped"
end

-- 同じキーで開閉する（<M-a> のローカル下書きと揃える）。
function M.toggle()
  if M.is_open() then
    return M.close()
  end
  return M.open()
end

function M.clear()
  if not M.is_open() then
    return false, "picker is not open"
  end
  draft_buf.clear(ui.draft_buf)
  return true, "cleared"
end

-- プレビューの操作。コマンドとテストから呼ぶ。
-- \x15 は <C-u>（0x05 ではない）、\x04 は <C-d>。
function M.preview_scroll_up()
  return preview_scroll("\x15")
end

function M.preview_scroll_down()
  return preview_scroll("\x04")
end

-- 最下部へ戻して追従を再開する。ノーマルモードの G から呼ばれる。
function M.preview_follow()
  local win = preview_window()
  if not win then
    return false, "preview is not available"
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! G")
  end)
  preview_paused = false
  update_preview(true)
  return true
end

function M.preview_scroll_left()
  return preview_scroll_horizontal(PREVIEW_HSCROLL .. "zh")
end

function M.preview_scroll_right()
  return preview_scroll_horizontal(PREVIEW_HSCROLL .. "zl")
end

-- 取得や凍結の状態。テストから確認するために公開する。
function M.preview_state()
  if not M.is_open() then
    return nil
  end
  return {
    paused = preview_paused,
    visible = preview_window() ~= nil,
    failures = preview_failures,
    pane_id = preview_pane_id,
    buffer = ui.preview_buf,
    window = preview_window(),
    lines = preview_last_lines or {},
  }
end

-- 手動の取り直し。凍結中でも取得する。
function M.refresh_preview()
  return update_preview(true)
end

return M
