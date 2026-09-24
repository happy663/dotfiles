package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local function pane(id, status)
  return {
    pane_id = id,
    status = status,
    stale = false,
    task = "#task-" .. id,
    project = "dotfiles",
    session = "test",
    window_index = tonumber(id) or 1,
  }
end

local pane_lists = {
  { pane("1", "running") },
  {
    pane("1", "running"),
    pane("2", "running"),
    pane("3", "running"),
    pane("4", "running"),
    pane("5", "running"),
    pane("6", "running"),
    pane("7", "running"),
    pane("8", "running"),
    pane("9", "running"),
    pane("10", "running"),
    pane("11", "running"),
    pane("12", "running"),
  },
}
local list_call = 0

package.loaded["agent_term.picker.panes"] = {
  list = function()
    list_call = list_call + 1
    return pane_lists[math.min(list_call, #pane_lists)]
  end,
}

package.loaded["agent_term.draft_buf"] = {
  create_input_buffer = function(name)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    return buf
  end,
  apply_send_keymaps = function() end,
  read_content = function()
    return ""
  end,
  clear = function() end,
}

package.loaded["agent_term.picker.remote_send"] = {
  send = function()
    return true, "sent"
  end,
}

local send_to = require("agent_term.picker.send_to")

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

local opened = send_to.open()
assert_eq(opened, true, "picker opens")

local draft_win = vim.api.nvim_get_current_win()
local list_win = nil
for _, win in ipairs(vim.api.nvim_list_wins()) do
  local cfg = vim.api.nvim_win_get_config(win)
  -- プレビューも浮きウィンドウなので、タイトルで一覧を特定する。
  local title = cfg.title and (type(cfg.title) == "table" and cfg.title[1][1] or cfg.title)
  if win ~= draft_win and cfg.relative ~= "" and title == " Agents " then
    list_win = win
    break
  end
end
assert(list_win, "agent list window was not found")
-- 新レイアウト: 下段 prompt | agent は同じ高さで、下書きの高さが 8 なので
-- 件数が少なくても下段は 8 行になる。
assert_eq(vim.api.nvim_win_get_height(list_win), 8, "initial list height (bottom row)")

local refreshed = send_to.refresh()
assert_eq(refreshed, true, "picker refreshes")
-- 件数 12 で下段が max(8, 10) の 10 行に伸びる。
assert_eq(vim.api.nvim_win_get_height(list_win), 10, "refreshed list height")

local list_cfg = vim.api.nvim_win_get_config(list_win)
local draft_cfg = vim.api.nvim_win_get_config(draft_win)
assert_eq(draft_cfg.row, list_cfg.row, "prompt and agent share the bottom row")
assert_true(
  list_cfg.col > draft_cfg.col,
  "agent is right of prompt (col " .. draft_cfg.col .. " vs " .. list_cfg.col .. ")"
)

send_to.close()
print("agent_term send-to refresh tests passed")
