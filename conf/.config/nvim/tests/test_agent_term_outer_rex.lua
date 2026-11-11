package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

-- agent_term.outer.rex のテスト。
-- Rex 向けの送り先。OSC 7501 の報告に、バッファごとの id（agent/<bufnr>）を付けて
-- 外側の端末（Rex）へそのまま転送する。

local ESC = "\27"
local ST = ESC .. "\\"
local OSC = ESC .. "]7501;"

local rex = require("agent_term.outer.rex")

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

test("encode: id が無い報告に agent/<bufnr> を付ける", function()
  assert_eq(
    OSC .. "state=working:app=claude-code:title=eA==:id=agent/12" .. ST,
    rex.encode(12, { { "state", "working" }, { "app", "claude-code" }, { "title", "eA==" } }),
    "root report"
  )
end)

test("encode: id がある報告は agent/<bufnr>/ の下に入れる", function()
  assert_eq(
    OSC .. "state=blocked:id=agent/12/sub:kind=permission" .. ST,
    rex.encode(12, { { "state", "blocked" }, { "id", "sub" }, { "kind", "permission" } }),
    "child report"
  )
end)

test("encode: 元の配列は書き換えない", function()
  local pairs = { { "state", "blocked" }, { "id", "sub" } }
  rex.encode(12, pairs)
  assert_eq({ { "state", "blocked" }, { "id", "sub" } }, pairs, "input untouched")
end)

test("new: report は id を付けて送り、clear はそのバッファの記録を消す", function()
  local sent = {}
  local sink = rex.new({
    send = function(data)
      table.insert(sent, data)
    end,
  })

  sink.report(7, { { "state", "idle" }, { "app", "pi" } })
  sink.report(7, { { "state", "clear" } })
  sink.clear(7)

  assert_eq({
    OSC .. "state=idle:app=pi:id=agent/7" .. ST,
    OSC .. "state=clear:id=agent/7" .. ST,
    OSC .. "state=clear:id=agent/7" .. ST,
  }, sent, "sent sequences")
end)

test("available: REX_SESSION があり nvim_ui_send が使えるときだけ真", function()
  local saved = vim.env.REX_SESSION
  vim.env.REX_SESSION = nil
  assert_eq(false, rex.available(), "outside Rex")
  vim.env.REX_SESSION = ""
  assert_eq(false, rex.available(), "empty REX_SESSION")
  vim.env.REX_SESSION = "session:test"
  assert_eq(vim.api.nvim_ui_send ~= nil, rex.available(), "inside Rex")
  vim.env.REX_SESSION = saved
end)

print("ALL OK")
