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

assert_eq(
  agent_fork.build_agent_command("claude", "claude-session-id"),
  "nvim +'AgentClaude --resume claude-session-id --fork-session'",
  "Claude fork command"
)
assert_eq(
  agent_fork.build_agent_command("pi", "pi-session-id"),
  "nvim +'AgentPi --fork pi-session-id'",
  "Pi fork command"
)

-- split_with_command: 外側のマルチプレクサ（tmux / herdr）で右に分割し、コマンドを起動する
local function recorder(responses)
  local calls = {}
  return calls,
    function(argv)
      table.insert(calls, argv)
      return responses[#calls] or { code = 0, stdout = "" }
    end
end

local function assert_calls(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(("%s\nexpected: %s\n  actual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

-- tmux の中
local calls, system = recorder({})
local ok = agent_fork.split_with_command("/tmp/project dir", "nvim +'AgentPi --fork x'", {
  env = { TMUX = "/tmp/tmux-501/default,1,0" },
  system = system,
})
assert_eq(ok, true, "tmux split ok")
assert_calls({
  { "tmux", "split-window", "-h", "-c", "/tmp/project dir", "nvim +'AgentPi --fork x'" },
}, calls, "tmux split")

-- herdr の中: 分割 → シェルの起動待ち → コマンドを入力
calls, system = recorder({
  { code = 0, stdout = vim.json.encode({ result = { pane = { pane_id = "w1:p7" }, type = "pane_info" } }) },
})
ok = agent_fork.split_with_command("/tmp/project dir", "nvim +'AgentPi --fork x'", {
  env = { HERDR_ENV = "1", HERDR_PANE_ID = "w1:p1" },
  system = system,
})
assert_eq(ok, true, "herdr split ok")
assert_calls({
  { "herdr", "pane", "split", "w1:p1", "--direction", "right", "--cwd", "/tmp/project dir", "--focus" },
  { "herdr", "pane", "wait-output", "w1:p7", "--regex", "\\S", "--source", "visible", "--timeout", "5000" },
  { "herdr", "pane", "run", "w1:p7", "nvim +'AgentPi --fork x'" },
}, calls, "herdr split")

-- herdr の分割に失敗したら false
calls, system = recorder({ { code = 1, stdout = "" } })
ok = agent_fork.split_with_command("/tmp", "true", {
  env = { HERDR_ENV = "1", HERDR_PANE_ID = "w1:p1" },
  system = system,
})
assert_eq(ok, false, "herdr split failure")
assert_eq(#calls, 1, "no run after failed split")

-- どちらの中でもなければ false（何も実行しない）
calls, system = recorder({})
ok = agent_fork.split_with_command("/tmp", "true", { env = {}, system = system })
assert_eq(ok, false, "outside multiplexer")
assert_eq(#calls, 0, "nothing executed outside multiplexer")

print("agent_term fork tests passed")
