package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local draft = require("agent_term.draft")
local terminals = require("agent_term.terminals")
local state = require("agent_term.state")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

vim.cmd("tabnew")
vim.cmd("terminal cat")
local term = vim.api.nvim_get_current_buf()
vim.cmd("belowright split")
draft.open_input_buffer({ claude_bufnr = term, draft_height = 15 })
vim.cmd("resize 7")
assert_eq(vim.api.nvim_win_get_height(0), 7, "draft resize setup")
draft.hide()
assert_eq(vim.t.claude_input_height, 7, "draft height saved")
local ok, msg = draft.focus_or_open({ claude_bufnr = term, draft_height = 15 })
assert(ok, msg)
assert_eq(vim.api.nvim_win_get_height(0), 7, "draft height restored")

vim.api.nvim_buf_set_lines(state.get_draft_bufnr(), 0, -1, false, { "hello", "world" })
local sent = {}
local original_send = terminals.send_command
terminals.send_command = function(target, command, opts)
  sent.target = target
  sent.command = command
  sent.opts = opts
  return true, "sent"
end
local send_ok, send_msg = draft.send_draft({ hide_after = false })
assert(send_ok, send_msg)
assert_eq(sent.command, "hello\nworld", "draft content sent")
assert_eq(sent.opts.paste, true, "bracketed paste enabled")
assert_eq(#vim.api.nvim_buf_get_lines(state.get_draft_bufnr(), 0, -1, false), 1, "draft cleared")
terminals.send_command = original_send

print("agent_term refactor tests passed")
