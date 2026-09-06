package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local layouts = require("agent_term.layouts")
local pi_session_opts = nil
layouts.open_agent_pi = function(opts)
  pi_session_opts = opts
end

local fork_calls = {}
package.loaded["agent_term.fork"] = {
  open = function(name, source)
    table.insert(fork_calls, { name = name, source = source })
    return true
  end,
}

local commands = require("agent_term.commands")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function assert_command_exists(name)
  assert_eq(vim.fn.exists(":" .. name), 2, name .. " registration")
end

commands.setup()

assert_command_exists("AgentClaudeSession")
assert_command_exists("AgentCodexSession")
assert_command_exists("AgentPiSession")
assert_command_exists("AgentSession")
assert_command_exists("AgentFork")
assert_command_exists("AgentClaudeFork")
assert_command_exists("AgentPiFork")

vim.cmd("AgentPiSession")
assert_eq(pi_session_opts.command, "ccsession --pi", "AgentPiSession command")
assert_eq(pi_session_opts.open_draft, false, "AgentPiSession draft setting")

vim.cmd("AgentFork")
assert_eq(fork_calls[1].name, "AgentFork", "AgentFork command name")
assert_eq(fork_calls[1].source, nil, "AgentFork auto-detects source")

vim.cmd("AgentClaudeFork")
assert_eq(fork_calls[2].name, "AgentClaudeFork", "AgentClaudeFork command name")
assert_eq(fork_calls[2].source, "claude", "AgentClaudeFork source")

vim.cmd("AgentPiFork")
assert_eq(fork_calls[3].name, "AgentPiFork", "AgentPiFork command name")
assert_eq(fork_calls[3].source, "pi", "AgentPiFork source")

local mapping = vim.fn.maparg("<leader>ak", "n", false, true)
assert_eq(mapping.rhs, ":AgentFork<CR>", "shared fork keymap")

print("agent_term command tests passed")
