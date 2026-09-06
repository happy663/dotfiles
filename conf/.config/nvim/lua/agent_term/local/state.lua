local M = {}

function M.is_valid_buf(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

-- タブ単位の MRU 追跡（タブをまたぐためモジュールローカルに保持）
local mru_work_tabpage = nil
local mru_agent_tabpage = nil

-- 指定タブが Agent 専用タブかどうか。
-- 「Agent 専用」は明示マーカー (t:agent_pure) で判定する。
-- ドラフト/ターミナルの有無だけで判定すると、ファイル編集ウィンドウを併設した
-- hybrid レイアウトまで Agent タブ扱いされてしまうため。
-- tabpage 省略時は 0 = 現在タブ。
function M.is_agent_tabpage(tabpage)
  tabpage = tabpage or 0

  local ok, pure = pcall(vim.api.nvim_tabpage_get_var, tabpage, "agent_pure")
  if not ok or not pure then
    return false
  end

  -- マーカーが残っていても中身が空のタブまで Agent と扱わないよう、最低限の構成は確認する
  local ok_input, input_bufnr = pcall(vim.api.nvim_tabpage_get_var, tabpage, "agent_input_bufnr")
  if ok_input and M.is_valid_buf(input_bufnr) then
    return true
  end

  local ok_term, term_bufnr = pcall(vim.api.nvim_tabpage_get_var, tabpage, "agent_terminal_bufnr")
  if ok_term and M.is_valid_buf(term_bufnr) and vim.bo[term_bufnr].buftype == "terminal" then
    return true
  end

  return false
end

-- 現在タブを Agent 専用タブとしてマークする。
-- レイアウト生成関数 (open_agent_claude 等) から呼ぶこと。
function M.mark_current_tab_as_agent()
  vim.t.agent_pure = true
end

-- タブを Agent / 非Agent に分類して MRU に記録する。
-- TabLeave 時など、タブの構成が確定した状態で呼ぶこと。
function M.record_tabpage(tabpage)
  tabpage = tabpage or vim.api.nvim_get_current_tabpage()
  if not vim.api.nvim_tabpage_is_valid(tabpage) then
    return
  end

  if M.is_agent_tabpage(tabpage) then
    mru_agent_tabpage = tabpage
  else
    mru_work_tabpage = tabpage
  end
end

-- 最近使った非Agentタブ（作業タブ）。無効化されていれば nil。
function M.get_work_tabpage()
  if
    mru_work_tabpage
    and vim.api.nvim_tabpage_is_valid(mru_work_tabpage)
    and not M.is_agent_tabpage(mru_work_tabpage)
  then
    return mru_work_tabpage
  end
  return nil
end

-- 最近使った Agent タブ。無効化されていれば nil。
function M.get_agent_tabpage()
  if
    mru_agent_tabpage
    and vim.api.nvim_tabpage_is_valid(mru_agent_tabpage)
    and M.is_agent_tabpage(mru_agent_tabpage)
  then
    return mru_agent_tabpage
  end
  return nil
end

function M.get_draft_bufnr()
  if M.is_valid_buf(vim.t.agent_input_bufnr) then
    return vim.t.agent_input_bufnr
  end
  return nil
end

function M.set_draft_bufnr(bufnr)
  vim.t.agent_input_bufnr = bufnr
end

function M.get_target_terminal_bufnr()
  if M.is_valid_buf(vim.t.agent_terminal_bufnr) and vim.bo[vim.t.agent_terminal_bufnr].buftype == "terminal" then
    return vim.t.agent_terminal_bufnr
  end
  return nil
end

function M.set_target_terminal_bufnr(bufnr)
  if M.is_valid_buf(bufnr) then
    vim.t.agent_terminal_bufnr = bufnr
  end
end

function M.get_fallback_target_patterns(default_patterns)
  return vim.t.agent_input_fallback_target_patterns or default_patterns
end

function M.set_fallback_target_patterns(patterns)
  if type(patterns) == "string" and patterns ~= "" then
    vim.t.agent_input_fallback_target_patterns = patterns
  elseif type(patterns) == "table" and #patterns > 0 then
    vim.t.agent_input_fallback_target_patterns = patterns
  end
end

function M.set_prev_winid(winid)
  vim.t.agent_input_prev_winid = winid
end

function M.get_prev_winid()
  return vim.t.agent_input_prev_winid
end

local function normalize_height(height)
  if type(height) == "number" and height > 0 then
    return height
  end
  return nil
end

function M.get_draft_height(default_height)
  return normalize_height(vim.t.agent_input_height) or normalize_height(default_height)
end

function M.set_draft_height(height)
  local normalized = normalize_height(height)
  if normalized then
    vim.t.agent_input_height = normalized
  end
end

function M.set_agent_claude_pair_state(pair_state)
  vim.t.agent_claude_pair_active = true
  vim.t.agent_claude_pair_left_winid = pair_state.left_winid
  vim.t.agent_claude_pair_right_winid = pair_state.right_winid
  vim.t.agent_claude_pair_input_winid = pair_state.input_winid
  vim.t.agent_claude_pair_left_bufnr = pair_state.left_bufnr
  vim.t.agent_claude_pair_right_bufnr = pair_state.right_bufnr
  M.set_target_terminal_bufnr(pair_state.left_bufnr)
end

function M.is_agent_claude_pair_active()
  return vim.t.agent_claude_pair_active == true
end

function M.get_agent_claude_pair_cycle()
  return {
    vim.t.agent_claude_pair_input_winid,
    vim.t.agent_claude_pair_left_winid,
    vim.t.agent_claude_pair_right_winid,
  }
end

return M
