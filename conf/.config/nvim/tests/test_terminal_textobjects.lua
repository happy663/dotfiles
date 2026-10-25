package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local terminal = require("core.terminal_textobjects")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local lines = {
  " shell info │ cwd",
  "❯ echo first",
  "first output",
  "",
  " shell info │ cwd",
  "❯ echo second",
  "second output",
  "",
}

assert_eq(terminal.is_prompt_line("❯ echo hi"), true, "❯ はシェルプロンプト")
assert_eq(terminal.is_prompt_line(" ⏺ response"), false, "応答行はシェルプロンプトではない")
assert_eq(terminal.is_info_line(" shell │ cwd"), true, "p10k 情報行を判別")
assert_eq(terminal.is_info_line("command output"), false, "通常出力は情報行ではない")

local start, stop = terminal.turn_range(lines, 3)
assert_eq(start, 2, "1件目のコマンド行")
assert_eq(stop, 3, "次の情報行より前かつ末尾空行を除く")
start, stop = terminal.turn_range(lines, 7)
assert_eq(start, 6, "2件目のコマンド行")
assert_eq(stop, 7, "最終出力行")
start, stop = terminal.turn_range(lines, 1)
assert_eq(start, nil, "プロンプトより上では範囲なし")
assert_eq(stop, nil, "プロンプトより上では範囲なし")

local prompts = terminal.prompt_rows(lines)
assert_eq(table.concat(prompts, ","), "2,6", "プロンプト行一覧")
assert_eq(terminal.jump_target(prompts, 2, 1, #lines), 6, "次のプロンプト")
assert_eq(terminal.jump_target(prompts, 6, 1, #lines), #lines, "次が無ければ最新")
assert_eq(terminal.jump_target(prompts, 6, -1, #lines), 2, "前のプロンプト")

-- 通常terminalには通常terminal専用マップだけが登録される
terminal.setup()
vim.cmd("enew")
local buf = vim.api.nvim_get_current_buf()
local job = vim.fn.termopen("cat")
local iC = vim.fn.maparg("iC", "o", false, true)
local ic = vim.fn.maparg("ic", "o", false, true)
assert_eq(iC.buffer, 1, "iC はbuffer-local")
assert_eq(iC.desc, "inner terminal turn", "通常terminal用 iC")
assert_eq(ic.buffer, nil, "Agent用 ic は通常terminalへ登録しない")
vim.fn.jobstop(job)
vim.api.nvim_buf_delete(buf, { force = true })

print("terminal_textobjects tests passed")
