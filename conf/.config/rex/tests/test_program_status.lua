-- conf/.config/rex/nvim/program_status.lua のテスト。
-- Neovim の :terminal 内のエージェントが出した OSC 7501（Program Status Protocol）を
-- 受け取り、バッファごとの id（agent/<bufnr>）を付けて外側の端末（Rex）へ転送する。

local ESC = "\27"
local ST = ESC .. "\\"
local OSC = ESC .. "]7501;"

local module_path = vim.fn.getcwd() .. "/conf/.config/rex/nvim/program_status.lua"
local ps = dofile(module_path)

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

-- parse ---------------------------------------------------------------------

test("parse: key=value の組を順番どおりに返す", function()
  assert_eq({
    { "state", "working" },
    { "app", "claude-code" },
    { "title", "eA==" },
  }, ps.parse(OSC .. "state=working:app=claude-code:title=eA=="), "pairs")
end)

test("parse: 終端（ST / BEL）が付いていても同じ結果になる", function()
  local expected = { { "state", "done" } }
  assert_eq(expected, ps.parse(OSC .. "state=done" .. ST), "ST")
  assert_eq(expected, ps.parse(OSC .. "state=done\7"), "BEL")
end)

test("parse: OSC 7501 以外は nil", function()
  assert_eq(nil, ps.parse(ESC .. "]133;A"), "OSC 133")
  assert_eq(nil, ps.parse(ESC .. "]75010;state=done"), "似た番号")
end)

test("parse: 機能検出の問い合わせ（?）は nil", function()
  assert_eq(nil, ps.parse(OSC .. "?"), "query")
end)

-- handle（転送する文字列を作る）---------------------------------------------

test("handle: id が無い報告に agent/<bufnr> を付ける", function()
  assert_eq(
    OSC .. "state=working:app=claude-code:title=eA==:id=agent/12" .. ST,
    ps.handle(12, OSC .. "state=working:app=claude-code:title=eA=="),
    "root report"
  )
end)

test("handle: id がある報告は agent/<bufnr>/ の下に入れる", function()
  assert_eq(
    OSC .. "state=blocked:id=agent/12/sub:kind=permission" .. ST,
    ps.handle(12, OSC .. "state=blocked:id=sub:kind=permission"),
    "child report"
  )
end)

test("handle: id の無い clear は、そのバッファの記録だけを消す", function()
  assert_eq(OSC .. "state=clear:id=agent/12" .. ST, ps.handle(12, OSC .. "state=clear"), "clear")
end)

test("handle: 転送対象でないシーケンスは nil", function()
  assert_eq(nil, ps.handle(12, ESC .. "]133;A"), "OSC 133")
  assert_eq(nil, ps.handle(12, OSC .. "?"), "query")
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

test("setup: 端末内の OSC 7501 を転送し、終了時にそのバッファの記録を消す", function()
  local sent = {}
  ps.setup({
    enabled = true,
    send = function(data)
      table.insert(sent, data)
    end,
  })

  local buf = run_in_terminal("\\033]7501;state=working:app=claude-code\\033\\\\done\\n")
  vim.wait(5000, function()
    return #sent >= 2
  end, 10)

  assert_eq({
    OSC .. "state=working:app=claude-code:id=agent/" .. buf .. ST,
    OSC .. "state=clear:id=agent/" .. buf .. ST,
  }, sent, "forwarded sequences")
end)

test("setup: OSC 7501 以外は転送しない", function()
  local sent = {}
  ps.setup({
    enabled = true,
    send = function(data)
      table.insert(sent, data)
    end,
  })

  run_in_terminal("\\033]133;A\\033\\\\done\\n")
  vim.wait(300)

  assert_eq({}, sent, "nothing forwarded")
end)

test("setup: enabled = false なら何も転送しない", function()
  local sent = {}
  ps.setup({
    enabled = false,
    send = function(data)
      table.insert(sent, data)
    end,
  })

  run_in_terminal("\\033]7501;state=working\\033\\\\done\\n")
  vim.wait(300)

  assert_eq({}, sent, "nothing forwarded")
end)

print("ALL OK")
