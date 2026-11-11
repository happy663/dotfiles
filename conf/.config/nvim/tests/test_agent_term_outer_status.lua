package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

-- agent_term.outer.status のテスト。
-- :terminal 内のエージェントが出した OSC 7501（Program Status Protocol）を受け取り、
-- 外側の端末向けの送り先（sink）へ配る。対応確認（OSC 7501 ; ?）には代わりに返事をする。

local ESC = "\27"
local ST = ESC .. "\\"
local OSC = ESC .. "]7501;"

local status = require("agent_term.outer.status")

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

-- parse / is_query -------------------------------------------------------------

test("parse: key=value の組を順番どおりに返す", function()
  assert_eq({
    { "state", "working" },
    { "app", "claude-code" },
    { "title", "eA==" },
  }, status.parse(OSC .. "state=working:app=claude-code:title=eA=="), "pairs")
end)

test("parse: 終端（ST / BEL）が付いていても同じ結果になる", function()
  local expected = { { "state", "done" } }
  assert_eq(expected, status.parse(OSC .. "state=done" .. ST), "ST")
  assert_eq(expected, status.parse(OSC .. "state=done\7"), "BEL")
end)

test("parse: OSC 7501 以外と対応確認は nil", function()
  assert_eq(nil, status.parse(ESC .. "]133;A"), "OSC 133")
  assert_eq(nil, status.parse(ESC .. "]75010;state=done"), "似た番号")
  assert_eq(nil, status.parse(OSC .. "?"), "query")
end)

test("is_query: 対応確認だけを真にする", function()
  assert_eq(true, status.is_query(OSC .. "?"), "query")
  assert_eq(true, status.is_query(OSC .. "?" .. ST), "query with ST")
  assert_eq(false, status.is_query(OSC .. "state=idle"), "report")
  assert_eq(false, status.is_query(ESC .. "]133;A"), "other OSC")
end)

-- setup（実際の :terminal での動作）------------------------------------------

-- ターミナルバッファで printf を動かし、終了するまで待つ
local function run_in_terminal(printf_arg)
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  local exited = false
  vim.fn.jobstart({ "printf", printf_arg }, {
    term = true,
    on_exit = function()
      exited = true
    end,
  })
  assert_eq(
    true,
    vim.wait(5000, function()
      return exited
    end, 10),
    "terminal job exited"
  )
  return buf
end

-- 呼ばれた内容を記録するだけの送り先
local function fake_sink()
  local calls = {}
  return {
    calls = calls,
    report = function(bufnr, pairs)
      table.insert(calls, { "report", bufnr, pairs })
    end,
    clear = function(bufnr)
      table.insert(calls, { "clear", bufnr })
    end,
  }
end

test("setup: 報告を送り先へ配り、終了時にそのバッファを clear する", function()
  local sink = fake_sink()
  status.setup({ sinks = { sink } })

  local buf = run_in_terminal("\\033]7501;state=working:app=claude-code\\033\\\\done\\n")
  vim.wait(5000, function()
    return #sink.calls >= 2
  end, 10)

  assert_eq({
    { "report", buf, { { "state", "working" }, { "app", "claude-code" } } },
    { "clear", buf },
  }, sink.calls, "sink calls")
end)

test("setup: 送り先が複数あれば全部に配る", function()
  local a, b = fake_sink(), fake_sink()
  status.setup({ sinks = { a, b } })

  local buf = run_in_terminal("\\033]7501;state=done\\033\\\\done\\n")
  vim.wait(5000, function()
    return #a.calls >= 2 and #b.calls >= 2
  end, 10)

  local expected = { { "report", buf, { { "state", "done" } } }, { "clear", buf } }
  assert_eq(expected, a.calls, "sink a")
  assert_eq(expected, b.calls, "sink b")
end)

test("setup: OSC 7501 以外は配らない", function()
  local sink = fake_sink()
  status.setup({ sinks = { sink } })

  run_in_terminal("\\033]133;A\\033\\\\done\\n")
  vim.wait(300)

  assert_eq({}, sink.calls, "nothing reported")
end)

test("setup: 対応確認に返事をし、送り先へは配らない", function()
  local sink, replies = fake_sink(), {}
  status.setup({
    sinks = { sink },
    reply = function(bufnr, data)
      table.insert(replies, { bufnr, data })
    end,
  })

  local buf = run_in_terminal("\\033]7501;?\\033\\\\done\\n")
  vim.wait(5000, function()
    return #replies >= 1
  end, 10)
  vim.wait(300)

  assert_eq({ { buf, OSC .. "?" .. ST } }, replies, "reply")
  assert_eq({}, sink.calls, "nothing reported")
end)

test("setup: 送り先がなければ返事も配信もしない", function()
  local replies = {}
  status.setup({
    sinks = {},
    reply = function(bufnr, data)
      table.insert(replies, { bufnr, data })
    end,
  })

  run_in_terminal("\\033]7501;?\\033\\\\\\033]7501;state=working\\033\\\\done\\n")
  vim.wait(300)

  assert_eq({}, replies, "no reply")
end)

test("setup: 返事は端末内のプログラムの入力に届く", function()
  status.setup({ sinks = { fake_sink() } })

  -- 端末を raw にして問い合わせを出し、返ってきた 10 バイト（ESC ] 7501 ; ? ESC \）を od で表示する
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  local exited = false
  vim.fn.jobstart({
    "sh",
    "-c",
    "stty raw -echo; printf '\\033]7501;?\\033\\\\'; head -c 10 | od -An -c; stty sane",
  }, {
    term = true,
    on_exit = function()
      exited = true
    end,
  })
  vim.wait(5000, function()
    return exited
  end, 10)

  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  assert_eq(true, text:find("]   7   5   0   1   ;   ?", 1, true) ~= nil, "reply received by program:\n" .. text)
end)

print("ALL OK")
