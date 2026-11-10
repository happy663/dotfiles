package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

-- Neovim を tmux 内で動かしていても、Neovim から起動した Claude Code には
-- TMUX を引き継がないことを確かめる。
-- TMUX が残っていると Claude Code は /copy で tmux 用の DCS passthrough を出し、
-- Neovim の :terminal がそれを解釈できずに base64 文字列を画面に表示してしまう。

local FAKE_TMUX = "/tmp/fake-tmux-socket,1,0"
local END_MARKER = "FAKE_CLAUDE_END"

local function assert_true(value, message)
  if not value then
    error(message .. ": expected truthy, got " .. tostring(value))
  end
end

-- 本物の claude の代わりに、受け取った TMUX を表示するだけのスクリプトを PATH の先頭に置く
local fake_bin = vim.fn.tempname()
vim.fn.mkdir(fake_bin, "p")
local fake_claude = fake_bin .. "/claude"
vim.fn.writefile({ "#!/bin/sh", "printenv TMUX", "echo " .. END_MARKER }, fake_claude)
vim.fn.setfperm(fake_claude, "rwxr-xr-x")
vim.env.PATH = fake_bin .. ":" .. vim.env.PATH

-- tmux 内の Neovim を模す
vim.env.TMUX = FAKE_TMUX

local session_id = "00000000-0000-0000-0000-000000000000"
package.loaded["agent_term.fork"] = {
  open = function()
    return true
  end,
  resolve_current = function()
    return true, session_id
  end,
}

local layouts = require("agent_term.layouts")
local state = require("agent_term.local.state")
local commands = require("agent_term.commands")
commands.setup()

local function wait_output(bufnr)
  local lines = {}
  local done = vim.wait(5000, function()
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for _, line in ipairs(lines) do
      if line == END_MARKER then
        return true
      end
    end
    return false
  end, 20)
  assert_true(done, "fake claude finished (buf " .. bufnr .. ")")
  return lines
end

local function assert_tmux_hidden(bufnr, label)
  local lines = wait_output(bufnr)
  for _, line in ipairs(lines) do
    if line:find("fake-tmux-socket", 1, true) then
      error(label .. ": TMUX was passed to claude: " .. table.concat(lines, "\n"))
    end
  end
end

-- 1. AgentClaude 相当
do
  local bufnr = layouts.open_agent_claude({ open_draft = false })
  assert_tmux_hidden(bufnr, "open_agent_claude")
end

-- 2. 引数付きでも TMUX は渡さない
do
  local bufnr = layouts.open_agent_claude({ args = "--dangerously-skip-permissions", open_draft = false })
  assert_tmux_hidden(bufnr, "open_agent_claude with args")
end

-- 3. Claude + Codex の Claude 側
do
  layouts.open_agent_claude_codex({ codex_command = "cat" })
  assert_tmux_hidden(state.get_target_terminal_bufnr(), "open_agent_claude_codex")
end

-- 4. AgentClaudeRestart（claude --resume）
do
  vim.cmd("tabnew")
  vim.cmd("AgentClaudeRestart")
  assert_tmux_hidden(vim.api.nvim_get_current_buf(), "AgentClaudeRestart")
end

-- Neovim 自身の TMUX は変えない（Neovim から tmux を操作する機能のため）
assert_true(vim.env.TMUX == FAKE_TMUX, "Neovim's own TMUX is kept")

print("agent_term claude env tests passed")

