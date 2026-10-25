package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local terminal = require("features.terminal_textobjects")
local nav = require("agent_term.message_nav")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

-- pi の OSC133 マーカー行判定
assert_eq(nav.classify_marker_line(""), "assistant", "空行は応答マーカー")
assert_eq(nav.classify_marker_line(nil), "assistant", "nil は応答マーカー")
assert_eq(nav.classify_marker_line(string.rep(" ", 80)), "user", "空白のみの行はユーザー")
assert_eq(nav.classify_marker_line(" こんにちは"), "assistant", "本文行はユーザーではない")

-- 前後のマーカー探索
local list = { 10, 40, 90 }
assert_eq(nav.neighbor(list, 0, 1), 10, "先頭より上から次へ")
assert_eq(nav.neighbor(list, 10, 1), 40, "現在位置より次へ")
assert_eq(nav.neighbor(list, 90, -1), 40, "現在位置より前へ")
assert_eq(nav.neighbor(list, 10, -1), nil, "先頭より前は無い")

local start, stop = nav.block_range(list, 45, 120)
assert_eq(start, 40, "ブロック開始")
assert_eq(stop, 89, "ブロック終了は次のマーカー手前")
assert_eq(nav.jump_target(list, 90, 1, 120), 120, "次が無ければ最新へ")
assert_eq(nav.trim_block_end({ "a", "b", "", "   " }, 1, 4), 2, "末尾空行を除去")

-- 通常terminalのマップをAgentバッファだけで明示的に上書きする
terminal.setup()
nav.setup()
vim.cmd("enew")
local pi_buf = vim.api.nvim_get_current_buf()
local pi_job = vim.fn.termopen("cat")
assert_eq(vim.fn.maparg("iC", "o", false, true).desc, "inner terminal turn", "attach前は通常terminal")
nav.attach(pi_buf, "pi")
assert_eq(vim.b[pi_buf].agent_message_nav_kind, "pi", "pi種別をbuffer変数へ記録")
assert_eq(vim.fn.maparg("iC", "o", false, true).desc, "inner agent turn", "piではAgent用iCに上書き")
assert_eq(vim.fn.maparg("ic", "o", false, true).desc, "inner agent message", "piにicを登録")
vim.fn.jobstop(pi_job)
vim.api.nvim_buf_delete(pi_buf, { force = true })

vim.cmd("enew")
local claude_buf = vim.api.nvim_get_current_buf()
local claude_job = vim.fn.termopen("cat")
nav.attach(claude_buf, "claude")
assert_eq(vim.b[claude_buf].agent_message_nav_kind, "claude", "claude種別をbuffer変数へ記録")
assert_eq(vim.fn.maparg("]c", "n", false, true).desc, "next agent message", "Claudeに]cを登録")
vim.fn.jobstop(claude_job)
vim.api.nvim_buf_delete(claude_buf, { force = true })

-- Agentレイアウト経由で作ったバッファだけが自動attachされる
local layouts = require("agent_term.layouts")
local layout_pi_buf = layouts.open_agent_pi({
  command = "cat",
  open_in_new_tab = false,
  open_draft = false,
})
assert_eq(vim.b[layout_pi_buf].agent_message_nav_kind, "pi", "AgentPi経由はpiとしてattach")
vim.fn.jobstop(vim.b[layout_pi_buf].terminal_job_id)
vim.api.nvim_buf_delete(layout_pi_buf, { force = true })

local layout_claude_buf = layouts.open_agent_claude({
  command = "cat",
  open_draft = false,
})
assert_eq(vim.b[layout_claude_buf].agent_message_nav_kind, "claude", "AgentClaude経由はclaudeとしてattach")
vim.fn.jobstop(vim.b[layout_claude_buf].terminal_job_id)
vim.api.nvim_buf_delete(layout_claude_buf, { force = true })

print("agent_term message_nav tests passed")
