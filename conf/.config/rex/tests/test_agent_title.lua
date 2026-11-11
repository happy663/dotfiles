-- conf/.config/rex/nvim/agent_title.lua のテスト。
-- :terminal 内のエージェント（OSC 7501 を出したバッファ）が OSC 0/2 で設定したタイトルを、
-- Neovim のタイトル（'title' / 'titlestring'）として外側の端末（Rex）へ出す。

local module_path = vim.fn.getcwd() .. "/conf/.config/rex/nvim/agent_title.lua"
local at = dofile(module_path)

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

-- compute（出すタイトルを決める）-----------------------------------------------

local A = { buf = 32, title = "Task A" }
local B = { buf = 40, title = "Task B" }

test("compute: エージェントがいなければ空文字", function()
  assert_eq("", at.compute({ agents = {}, current = 1 }), "no agents")
end)

test("compute: エージェントが 1 つならそのタイトル", function()
  assert_eq("Task A", at.compute({ agents = { A }, current = 1 }), "single")
end)

test("compute: 今いるバッファがエージェントならそれを出し、残りの数を付ける", function()
  assert_eq("Task B (+1)", at.compute({ agents = { A, B }, current = 40 }), "current agent")
end)

test("compute: 普通のバッファにいるときは最後に触ったエージェントを出す", function()
  assert_eq("Task B (+1)", at.compute({ agents = { A, B }, current = 1, last = 40 }), "last agent")
end)

test(
  "compute: 最後に触ったエージェントが居なくなっていたら最初のエージェント",
  function()
    assert_eq("Task A (+1)", at.compute({ agents = { A, B }, current = 1, last = 99 }), "fallback")
  end
)

test("compute: タイトルの制御文字は空白に置き換える", function()
  assert_eq("a b", at.compute({ agents = { { buf = 5, title = "a\nb" } }, current = 5 }), "control chars")
end)

-- setup（実際の :terminal での動作）------------------------------------------

local ESC7501 = "\\033]7501;state=working\\033\\\\"
local function osc2(title)
  return "\\033]2;" .. title .. "\\007"
end

-- ターミナルバッファでコマンドを動かし続け、バッファ番号とジョブ ID を返す
local function open_terminal(output)
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  local job = vim.fn.jobstart({ "sh", "-c", "printf '" .. output .. "'; sleep 30" }, { term = true })
  return buf, job
end

local function wait_title(expected, message)
  local actual
  vim.wait(3000, function()
    actual = at.titlestring()
    return actual == expected
  end, 10)
  assert_eq(expected, actual, message)
end

test("setup: enabled = false なら 'title' を変えない", function()
  vim.o.title = false
  at.setup({ enabled = false })
  assert_eq(false, vim.o.title, "'title'")
end)

test("setup: enabled = true なら 'title' をオンにし、'titlestring' から呼ぶ", function()
  at.setup({ enabled = true })
  assert_eq(true, vim.o.title, "'title'")
  assert_eq(true, vim.o.titlestring:find("rex_agent_title", 1, true) ~= nil, "'titlestring'")
end)

local jobs = {}

test("setup: エージェントのタイトルを出す", function()
  local _, job = open_terminal(ESC7501 .. osc2("Task A"))
  table.insert(jobs, job)
  wait_title("Task A", "agent A")
end)

test("setup: OSC 7501 を出さない端末（普通のシェル）は数えない", function()
  local _, job = open_terminal(osc2("zsh"))
  table.insert(jobs, job)
  wait_title("Task A", "plain shell ignored")
end)

test("setup: タイトルをまだ出していないエージェントは数えない", function()
  local _, job = open_terminal(ESC7501)
  table.insert(jobs, job)
  wait_title("Task A", "agent without title ignored")
end)

local job_c
test("setup: 今いるエージェントを優先し、残りの数を付ける", function()
  _, job_c = open_terminal(ESC7501 .. osc2("Task C"))
  table.insert(jobs, job_c)
  wait_title("Task C (+1)", "agent C focused")
end)

test("setup: エージェントが終了したら数から外す", function()
  vim.fn.jobstop(job_c)
  wait_title("Task A", "agent C exited")
end)

for _, job in ipairs(jobs) do
  pcall(vim.fn.jobstop, job)
end

print("ALL OK")
