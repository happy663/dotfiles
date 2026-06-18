package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local state = require("agent_term.state")
local routing = require("agent_term.routing")
local draft = require("agent_term.draft")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function assert_true(value, message)
  if not value then
    error(message .. ": expected truthy, got " .. tostring(value))
  end
end

-- ヘルパー: Agentタブを1枚作り、ドラフトバッファを表示した状態にする
local function make_agent_tab()
  vim.cmd("tabnew")
  local tabpage = vim.api.nvim_get_current_tabpage()
  -- 擬似的なターミナル代わりに draft を開く（agent_input_bufnr がセットされる）
  local draft_bufnr = draft.open_input_buffer({ draft_height = 8 })
  return tabpage, draft_bufnr
end

-- 1. is_relocatable_file_buf: 通常ファイルのみ移送対象
do
  -- 名前なしバッファ → 対象外
  vim.cmd("enew")
  assert_eq(routing.is_relocatable_file_buf(vim.api.nvim_get_current_buf()), false, "noname buf is not relocatable")

  -- 通常ファイル → 対象
  vim.cmd("edit /tmp/agent_term_routing_dummy.txt")
  local file_buf = vim.api.nvim_get_current_buf()
  assert_eq(routing.is_relocatable_file_buf(file_buf), true, "named file buf is relocatable")

  -- nofile バッファ → 対象外
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].buftype = "nofile"
  assert_eq(routing.is_relocatable_file_buf(scratch), false, "nofile buf is not relocatable")
end

-- 2. is_agent_tabpage / MRU 記録
do
  routing.setup()

  -- 起動直後の最初のタブ（非Agent）
  local first_tab = vim.api.nvim_list_tabpages()[1]
  assert_eq(state.is_agent_tabpage(first_tab), false, "plain tab is not agent tab")

  local agent_tab = make_agent_tab()
  assert_eq(state.is_agent_tabpage(agent_tab), true, "tab with draft buffer is agent tab")
  assert_eq(state.is_agent_tabpage(first_tab), false, "first tab stays non-agent")

  -- 非Agentタブへ戻る（TabLeave で agent_tab が agent MRU に記録される）
  vim.api.nvim_set_current_tabpage(first_tab)
  assert_eq(state.get_agent_tabpage(), agent_tab, "agent MRU recorded on tab leave")
  assert_eq(state.get_work_tabpage(), first_tab, "work MRU is the current non-agent tab")
end

-- 3. open_buf_in_work_tab: ファイルを作業タブで開く
do
  -- 現在 first_tab(非Agent) に居る前提
  local work_tab = vim.api.nvim_get_current_tabpage()
  local file_buf = vim.fn.bufadd("/tmp/agent_term_routing_open.txt")
  vim.fn.bufload(file_buf)

  -- Agentタブへ移動してから作業タブへ移送されることを確認
  local agent_tab = state.get_agent_tabpage()
  vim.api.nvim_set_current_tabpage(agent_tab)

  local ok = routing.open_buf_in_work_tab(file_buf, { 1, 0 })
  assert_true(ok, "open_buf_in_work_tab succeeds")
  assert_eq(vim.api.nvim_get_current_tabpage(), work_tab, "moved to work tab")
  assert_eq(vim.api.nvim_get_current_buf(), file_buf, "file buffer opened in work tab")
end

-- 4. goto_agent_draft: 別タブから Agent ドラフトへ移動してフォーカス
do
  local agent_tab = state.get_agent_tabpage()
  local draft_bufnr = nil
  do
    local ok, _ = pcall(vim.api.nvim_tabpage_get_var, agent_tab, "agent_input_bufnr")
    if ok then
      draft_bufnr = vim.api.nvim_tabpage_get_var(agent_tab, "agent_input_bufnr")
    end
  end

  -- 作業タブへ移動
  local work_tab = state.get_work_tabpage()
  vim.api.nvim_set_current_tabpage(work_tab)

  local ok = routing.goto_agent_draft()
  assert_true(ok, "goto_agent_draft succeeds")
  assert_eq(vim.api.nvim_get_current_tabpage(), agent_tab, "switched to agent tab")
  assert_eq(vim.api.nvim_get_current_buf(), draft_bufnr, "focused agent draft buffer")
end

print("agent_term routing tests passed")
