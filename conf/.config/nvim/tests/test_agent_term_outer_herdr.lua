package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

-- agent_term.outer.herdr のテスト。
-- herdr 向けの送り先。herdr 0.9.5 は OSC 7501 を理解しないので、報告を
-- `herdr pane report-agent` / `herdr pane release-agent` の呼び出しに変換する（issue #351）。

local herdr = require("agent_term.outer.herdr")

local function assert_eq(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(("%s\nexpected: %s\n  actual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write("FAIL: " .. name .. "\n" .. tostring(err) .. "\n")
    os.exit(1)
  end
  print("ok: " .. name)
end

-- 呼び出した argv を記録する送り先を作る。seq は 1 から順に増やす
local function new_sink()
  local calls = {}
  local n = 0
  local sink = herdr.new({
    bin = "herdr",
    pane_id = "w1:p1",
    run = function(argv)
      table.insert(calls, argv)
    end,
    seq = function()
      n = n + 1
      return n
    end,
  })
  return sink, calls
end

local function report_argv(agent, state, seq, message)
  local argv = { "herdr", "pane", "report-agent", "w1:p1", "--source", "dotfiles:agent-term", "--agent", agent }
  vim.list_extend(argv, { "--state", state })
  if message then
    vim.list_extend(argv, { "--message", message })
  end
  vim.list_extend(argv, { "--seq", tostring(seq) })
  return argv
end

local function release_argv(agent, seq)
  return {
    "herdr",
    "pane",
    "release-agent",
    "w1:p1",
    "--source",
    "dotfiles:agent-term",
    "--agent",
    agent,
    "--seq",
    tostring(seq),
  }
end

test("available: HERDR_ENV=1 と HERDR_PANE_ID があるときだけ真", function()
  local saved_env, saved_pane = vim.env.HERDR_ENV, vim.env.HERDR_PANE_ID
  vim.env.HERDR_ENV, vim.env.HERDR_PANE_ID = nil, nil
  assert_eq(false, herdr.available(), "outside herdr")
  vim.env.HERDR_ENV, vim.env.HERDR_PANE_ID = "1", ""
  assert_eq(false, herdr.available(), "empty pane id")
  vim.env.HERDR_ENV, vim.env.HERDR_PANE_ID = nil, "w1:p1"
  assert_eq(false, herdr.available(), "no HERDR_ENV")
  vim.env.HERDR_ENV, vim.env.HERDR_PANE_ID = "1", "w1:p1"
  assert_eq(true, herdr.available(), "inside herdr")
  vim.env.HERDR_ENV, vim.env.HERDR_PANE_ID = saved_env, saved_pane
end)

test("report: 状態を herdr の状態に変換して report-agent を呼ぶ", function()
  local sink, calls = new_sink()
  sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
  sink.report(3, { { "state", "blocked" }, { "app", "claude-code" }, { "kind", "permission" } })
  sink.report(3, { { "state", "done" }, { "app", "claude-code" } })
  sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
  sink.report(3, { { "state", "error" }, { "app", "claude-code" } })
  sink.report(3, { { "state", "idle" }, { "app", "claude-code" } })
  assert_eq({
    report_argv("claude", "working", 1),
    report_argv("claude", "blocked", 2),
    report_argv("claude", "idle", 3),
    report_argv("claude", "working", 4),
    report_argv("claude", "idle", 5, "error"),
    report_argv("claude", "idle", 6),
  }, calls, "state mapping")
end)

test("report: 同じ状態が続くときは送らない", function()
  local sink, calls = new_sink()
  sink.report(3, { { "state", "working" }, { "app", "pi" } })
  sink.report(3, { { "state", "working" }, { "app", "pi" } })
  sink.report(3, { { "state", "done" }, { "app", "pi" } })
  sink.report(3, { { "state", "idle" }, { "app", "pi" } })
  assert_eq({
    report_argv("pi", "working", 1),
    report_argv("pi", "idle", 2),
  }, calls, "dedupe")
end)

test("report: app が無ければ agent として送る", function()
  local sink, calls = new_sink()
  sink.report(3, { { "state", "working" } })
  assert_eq({ report_argv("agent", "working", 1) }, calls, "default agent label")
end)

test("report: id 付き（子の記録）と知らない状態は無視する", function()
  local sink, calls = new_sink()
  sink.report(3, { { "state", "blocked" }, { "id", "sub" }, { "app", "claude-code" } })
  sink.report(3, { { "state", "paused" }, { "app", "claude-code" } })
  sink.report(3, { { "app", "claude-code" } })
  assert_eq({}, calls, "ignored")
end)

test("clear: 最後に報告したバッファなら release-agent を呼ぶ", function()
  local sink, calls = new_sink()
  sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
  sink.clear(9) -- 報告していないバッファ
  sink.clear(3)
  sink.clear(3) -- 2 回目は何もしない
  assert_eq({
    report_argv("claude", "working", 1),
    release_argv("claude", 2),
  }, calls, "release once")
end)

test("report: state=clear は release-agent、その後の同じ状態は送り直す", function()
  local sink, calls = new_sink()
  sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
  sink.report(3, { { "state", "clear" } })
  sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
  assert_eq({
    report_argv("claude", "working", 1),
    release_argv("claude", 2),
    report_argv("claude", "working", 3),
  }, calls, "clear then report again")
end)

test(
  "report: 別のエージェントが報告したら、前のエージェントを release してから送る",
  function()
    local sink, calls = new_sink()
    sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
    sink.report(5, { { "state", "idle" }, { "app", "pi" } })
    sink.clear(3) -- もう最後の報告者ではない
    assert_eq({
      report_argv("claude", "working", 1),
      release_argv("claude", 2),
      report_argv("pi", "idle", 3),
    }, calls, "switch agent")
  end
)

test("report: run が失敗しても例外を外へ出さない", function()
  local sink = herdr.new({
    pane_id = "w1:p1",
    run = function()
      error("herdr not found")
    end,
  })
  sink.report(3, { { "state", "working" }, { "app", "claude-code" } })
  sink.clear(3)
end)

print("all herdr sink tests passed")
