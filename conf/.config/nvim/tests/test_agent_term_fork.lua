package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local agent_fork = require("agent_term.fork")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local sessions = {
  ["pi:303"] = "pi-session-id",
  ["claude:202"] = "claude-session-id",
}

local function read_session(source, pid)
  return sessions[source .. ":" .. pid]
end

local function children_by_parent()
  return {
    ["101"] = { "202", "303" },
    ["202"] = { "404" },
  }
end

local source, session_id = agent_fork.find_session("101", nil, {
  read_session = read_session,
  children_by_parent = children_by_parent,
})
assert_eq(source, "claude", "auto-detected source")
assert_eq(session_id, "claude-session-id", "auto-detected session")

source, session_id = agent_fork.find_session("101", "pi", {
  read_session = read_session,
  children_by_parent = children_by_parent,
})
assert_eq(source, "pi", "filtered source")
assert_eq(session_id, "pi-session-id", "filtered session")

local claude_command = agent_fork.build_split_command("claude", "claude-session-id", "/tmp/project dir")
assert(claude_command:find("AgentClaude %-%-resume claude%-session%-id %-%-fork%-session"), "Claude fork command")
assert(claude_command:find("tmux split%-window %-h"), "Claude tmux split")

local pi_command = agent_fork.build_split_command("pi", "pi-session-id", "/tmp/project dir")
assert(pi_command:find("AgentPi %-%-fork pi%-session%-id"), "Pi fork command")
assert(pi_command:find("tmux split%-window %-h"), "Pi tmux split")

print("agent_term fork tests passed")
