-- プレビューと送信が、ccsession 経由を含めて同じ Agent terminal を解決する。
-- RPC の式と一時ファイルは本物を使い、外部プロセスと chansend だけを差し替える。
-- nvim --headless -u NONE -l conf/.config/nvim/tests/test_agent_term_rpc_targets.lua
package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

package.loaded["agent_term.picker.panes"] = {
  exists = function()
    return true
  end,
}

local terminals = require("agent_term.local.terminals")
local preview = require("agent_term.picker.preview")
local remote_send = require("agent_term.picker.remote_send")
local config = require("agent_term.config")
local original_system = vim.system
local original_chansend = vim.fn.chansend
local original_get_all_terminals = terminals.get_all_terminals
local original_notify = vim.notify
local current_terminal
local sent
local preview_lines = { "first", "second", "last" }
local pane = { pane_id = "%test", nvim_server = vim.fn.getcwd(), command = "nvim" }

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(message .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
  end
end

terminals.get_all_terminals = function()
  return { current_terminal }
end
vim.notify = function() end
vim.fn.chansend = function(job_id, content)
  assert_eq(job_id, current_terminal.job_id, "送信先 job")
  sent[#sent + 1] = content
  return #content
end
vim.system = function(cmd)
  assert_eq(cmd[1], vim.v.progpath, "nvim RPC を使う")
  assert_eq(cmd[2], "--server", "server option")
  assert_eq(cmd[3], pane.nvim_server, "送信先 server")
  assert_eq(cmd[4], "--remote-expr", "remote expression option")
  return {
    wait = function()
      return { code = 0, stdout = vim.fn.eval(cmd[5]), stderr = "" }
    end,
  }
end

local failures = {}
local count = 0
local function test(name, fn)
  count = count + 1
  local ok, err = pcall(fn)
  if ok then
    print("ok - " .. name)
  else
    failures[#failures + 1] = name .. ": " .. tostring(err)
  end
end

for _, command in ipairs({
  "claude",
  "codex",
  "pi",
  "ccsession",
  "ccsession --codex",
  "ccsession --pi",
  "ccsession --all",
}) do
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "term://~/project//123:" .. command)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, preview_lines)
  current_terminal = { bufnr = buf, job_id = 123, name = vim.api.nvim_buf_get_name(buf) }

  test(command .. " のプレビューを取得できる", function()
    local lines, err = preview.fetch(pane)
    assert_eq(err, nil, "取得エラーなし")
    assert_eq(lines, preview_lines, "対象 terminal の内容")
  end)

  test(command .. " の入力をクリアしてプロンプトを送れる", function()
    sent = {}
    local ok, err = remote_send.send(pane, "hello")
    assert_eq(ok, true, "送信成功: " .. tostring(err))
    assert_eq(#sent, 3, "送信回数")
    assert_eq(sent, { config.draft.clear_input_sequence, "\27[200~hello\27[201~", "\r" }, "クリア・本文・改行")
  end)

  test(command .. " にクリアなしでプロンプトを送れる", function()
    sent = {}
    local ok, err = remote_send.send(pane, "hello", { clear_input = false })
    assert_eq(ok, true, "送信成功: " .. tostring(err))
    assert_eq(#sent, 2, "送信回数")
    assert_eq(sent, { "\27[200~hello\27[201~", "\r" }, "本文・改行")
  end)

  vim.api.nvim_buf_delete(buf, { force = true })
end

vim.system = original_system
vim.fn.chansend = original_chansend
terminals.get_all_terminals = original_get_all_terminals
vim.notify = original_notify

if #failures > 0 then
  error(table.concat(failures, "\n"))
end
print("agent_term RPC target tests passed (" .. count .. ")")
