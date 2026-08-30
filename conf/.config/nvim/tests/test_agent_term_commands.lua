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

vim.cmd("AgentPiSession")
assert_eq(pi_session_opts.command, "ccsession --pi", "AgentPiSession command")
assert_eq(pi_session_opts.open_draft, false, "AgentPiSession draft setting")

print("agent_term command tests passed")
