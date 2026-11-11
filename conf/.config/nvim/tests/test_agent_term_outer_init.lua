package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

-- agent_term.outer（入り口）のテスト。
-- 使える送り先（今は Rex のみ）を集め、1 つもなければ何もしない。
-- 送り先がない環境で対応確認に返事をすると、Claude Code はタイトルの状態記号を消してしまうため。

local outer = require("agent_term.outer")

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

local function autocmd_count(group, event)
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = group, event = event })
  return ok and #autocmds or 0
end

test("setup: Rex の外（送り先なし）では何もしない", function()
  vim.env.REX_SESSION = nil
  vim.o.title = false
  outer.setup()

  assert_eq(false, vim.o.title, "'title'")
  assert_eq(0, autocmd_count("agent_term_outer_status", "TermRequest"), "status autocmds")
  assert_eq(0, autocmd_count("agent_term_outer_title", "TermRequest"), "title autocmds")
end)

test("setup: Rex の中では状態の中継とタイトルを有効にする", function()
  vim.env.REX_SESSION = "session:test"
  outer.setup()

  assert_eq(true, vim.o.title, "'title'")
  assert_eq(1, autocmd_count("agent_term_outer_status", "TermRequest"), "status autocmds")
  assert_eq(1, autocmd_count("agent_term_outer_title", "TermRequest"), "title autocmds")
end)

test("setup: 送り先がなくなって呼び直したら止まる", function()
  vim.env.REX_SESSION = nil
  outer.setup()

  assert_eq(0, autocmd_count("agent_term_outer_status", "TermRequest"), "status autocmds")
  assert_eq(0, autocmd_count("agent_term_outer_title", "TermRequest"), "title autocmds")
end)

print("ALL OK")
