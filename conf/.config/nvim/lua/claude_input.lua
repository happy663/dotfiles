-- claude_input.lua
-- Claude Code向け入力バッファの作成と送信を管理するモジュール

local M = {}
M.defaults = {
  target_pattern = "claude",
}

-- タブが閉じられた際に、そのタブに紐づく [Claude Input] バッファを wipe するためのレジストリ
-- key: tabpage handle, value: bufnr
local tab_bufnr_registry = {}
local setup_done = false

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

-- target terminal が現タブで表示されているウィンドウ ID を返す。
-- 1. target_bufnr が現タブのウィンドウに存在すればその winid
-- 2. なければ target_pattern で再探索し、そのバッファの winid
-- 3. それでも見つからなければ nil
local function resolve_target_terminal_winid(target_bufnr, target_pattern)
  local current_tab_wins = vim.api.nvim_tabpage_list_wins(0)

  local function find_winid_for(bufnr)
    if not is_valid_buf(bufnr) then
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
    local bridge_ok, terminal_bridge = pcall(require, "terminal_bridge")
    if bridge_ok then
      local terminal = terminal_bridge.find_terminal_by_pattern(target_pattern, false)
      if terminal and is_valid_buf(terminal.bufnr) then
        local pwinid = find_winid_for(terminal.bufnr)
        if pwinid then
          return pwinid
        end
      end
    end
  end

  return nil
end

-- target terminal のウィンドウの下に horizontal split を作る。
-- target が見つからない場合は botright split にフォールバックする。
-- 戻り値: true = target の下に作成、false = フォールバック (botright)
local function open_split_below_target(target_bufnr, target_pattern, draft_height)
  local target_winid = resolve_target_terminal_winid(target_bufnr, target_pattern)
  if target_winid then
    vim.api.nvim_set_current_win(target_winid)
    vim.cmd("belowright split")
    if type(draft_height) == "number" and draft_height > 0 then
      vim.cmd("resize " .. tostring(draft_height))
    end
    return true
  end

  vim.cmd("botright split")
  if type(draft_height) == "number" and draft_height > 0 then
    vim.cmd("resize " .. tostring(draft_height))
  end
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

  local target_pattern = opts.target_pattern or vim.t.claude_input_target_pattern or M.defaults.target_pattern
  local draft_bufnr = get_draft_bufnr()

  if draft_bufnr then
    if focus_existing_draft(draft_bufnr) then
      return true, "Focused existing draft buffer"
    end

    -- バッファは存在するがウィンドウ未表示 → target terminal の下に再表示
    local target_bufnr = opts.claude_bufnr
    if not is_valid_buf(target_bufnr) then
      target_bufnr = vim.t.claude_terminal_bufnr
    end

    local via_target = open_split_below_target(target_bufnr, target_pattern, opts.draft_height)
    vim.api.nvim_win_set_buf(0, draft_bufnr)
    vim.wo.winfixheight = true
    vim.cmd("startinsert")
    if not via_target then
      notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
    end
    return true, "Opened existing draft buffer"
  end

  -- 新規作成パス
  local terminal_bufnr = opts.claude_bufnr
  if not is_valid_buf(terminal_bufnr) then
    terminal_bufnr = resolve_target_terminal_bufnr(target_pattern)
  end
  if not is_valid_buf(terminal_bufnr) then
    return false, "Target terminal not found for draft buffer"
  end

  local via_target = open_split_below_target(terminal_bufnr, target_pattern, opts.draft_height)
  M.open_input_buffer({
    claude_bufnr = terminal_bufnr,
    target_pattern = target_pattern,
  })
  if not via_target then
    notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
  end
  return true, "Opened draft buffer"
end

function M.open_input_buffer(opts)
  opts = opts or {}

  local bufnr = get_draft_bufnr()
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

  vim.t.claude_input_bufnr = bufnr
  tab_bufnr_registry[vim.api.nvim_get_current_tabpage()] = bufnr
  if opts.claude_bufnr and is_valid_buf(opts.claude_bufnr) then
    vim.t.claude_terminal_bufnr = opts.claude_bufnr
  end
  if type(opts.target_pattern) == "string" and opts.target_pattern ~= "" then
    vim.t.claude_input_target_pattern = opts.target_pattern
  end

  vim.api.nvim_win_set_buf(0, bufnr)
  vim.wo.winfixheight = true

  -- 補完ポップアップが下に表示されるよう候補数を制限
  -- local cmp_ok, cmp = pcall(require, "cmp")
  -- if cmp_ok then
  --   cmp.setup.buffer({
  --     performance = {
  --       max_view_entries = 5,
  --     },
  --   })
  -- end

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

-- claude-input のウィンドウを閉じる（バッファ・内容は保持）。
-- フォーカスは vim.t.claude_input_prev_winid → claude_terminal_bufnr の window → Vim default の順で解決する。
function M.hide()
  local bufnr = get_draft_bufnr()
  if not bufnr then
    return false, "Claude draft buffer not found"
  end

  local windows = vim.fn.win_findbuf(bufnr)
  if #windows == 0 then
    return false, "Claude draft buffer is not visible"
  end

  -- フォーカス候補を閉じる前に確定する
  local prev_winid = vim.t.claude_input_prev_winid
  local fallback_winid
  if is_valid_buf(vim.t.claude_terminal_bufnr) then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == vim.t.claude_terminal_bufnr then
        fallback_winid = winid
        break
      end
    end
  end

  -- claude-input を表示している全ウィンドウを閉じる
  for _, winid in ipairs(windows) do
    if vim.api.nvim_win_is_valid(winid) then
      pcall(vim.api.nvim_win_close, winid, false)
    end
  end

  -- フォーカス復帰
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

  -- 送信成功後、内部で clear と（オプションで）hide を実行する
  M.clear_draft()
  if hide_after then
    M.hide()
  end

  -- 送信後は常に target terminal の window にフォーカスを移す（hide() の prev_winid 復帰より優先）
  if is_valid_buf(claude_bufnr) then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == claude_bufnr then
        vim.api.nvim_set_current_win(winid)
        break
      end
    end
  end

  return true, message
end

function M.quote_to_draft(lines, opts)
  opts = opts or {}

  -- 各行に "> " プレフィックスを付与
  local quoted = {}
  for _, line in ipairs(lines) do
    table.insert(quoted, "> " .. line)
  end

  -- ドラフトバッファの取得・作成・表示
  local draft_bufnr = get_draft_bufnr()
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
    draft_bufnr = get_draft_bufnr()
    if not draft_bufnr then
      return false, "Failed to create draft buffer"
    end
  end

  -- 既存内容の確認
  local existing = vim.api.nvim_buf_get_lines(draft_bufnr, 0, -1, false)
  local has_content = not (#existing == 0 or (#existing == 1 and existing[1] == ""))

  -- 追記する行を組み立て
  local to_append = {}
  if has_content then
    table.insert(to_append, "")
  end
  for _, q in ipairs(quoted) do
    table.insert(to_append, q)
  end
  table.insert(to_append, "")

  -- ドラフトバッファに追記
  if has_content then
    vim.api.nvim_buf_set_lines(draft_bufnr, -1, -1, false, to_append)
  else
    vim.api.nvim_buf_set_lines(draft_bufnr, 0, -1, false, to_append)
  end

  -- ドラフトバッファにフォーカスして末尾でインサートモード
  if not need_open then
    local windows = vim.fn.win_findbuf(draft_bufnr)
    for _, winid in ipairs(windows) do
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

-- タブ閉じ時に、そのタブの claude-input バッファを wipe するための autocmd を登録する。
-- bufhidden = "hide" に変更したことによるバッファ残存・命名衝突を防ぐ。
-- 1 セッションで 1 回だけ呼べばよい。
function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  local group = vim.api.nvim_create_augroup("ClaudeInputTabCleanup", { clear = true })

  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      -- 現存タブが参照している bufnr は残す
      local live_bufnrs = {}
      for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
        local ok, bufnr = pcall(vim.api.nvim_tabpage_get_var, tabpage, "claude_input_bufnr")
        if ok and is_valid_buf(bufnr) then
          live_bufnrs[bufnr] = true
        end
      end

      -- 無効になった tabpage に紐づく bufnr を削除
      for tabpage, bufnr in pairs(tab_bufnr_registry) do
        if not vim.api.nvim_tabpage_is_valid(tabpage) then
          tab_bufnr_registry[tabpage] = nil
          if is_valid_buf(bufnr) and not live_bufnrs[bufnr] then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
        end
      end
    end,
  })
end

return M
