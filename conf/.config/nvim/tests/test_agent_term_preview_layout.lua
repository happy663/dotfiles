-- ピッカーのレイアウト計算（picker/layout.lua）のテスト。
-- ウィンドウを開かないので、純粋に寸法だけを検証する。
--
--   cd <repo root>
--   nvim --headless -l conf/.config/nvim/tests/test_agent_term_preview_layout.lua
package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local layout = require("agent_term.picker.layout")

local tests = {}
local function test(display, fn)
  tests[#tests + 1] = { display = display, fn = fn }
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function assert_true(value, message)
  if not value then
    error(message .. ": expected truthy, got " .. tostring(value))
  end
end

local function calc(list_count, columns, lines)
  return layout.calculate({
    columns = columns or 194,
    lines = lines or 45,
    list_count = list_count,
  })
end

test("左カラム + ギャップ + プレビューが全幅に一致する", function()
  local l = calc(1)
  assert_eq(l.left_width + l.gap + l.preview_width, l.total_width, "合計")
  assert_true(l.preview_visible, "広い画面ではプレビューを出す")
end)

test("プレビュー比率が 0.7 前後になる", function()
  local l = calc(1)
  local ratio = l.preview_width / l.total_width
  assert_true(ratio > 0.65 and ratio < 0.75, "比率: " .. tostring(ratio))
end)

test("一覧の高さが件数に追従する", function()
  assert_eq(calc(3).list_height, 3, "件数3")
  assert_eq(calc(1).list_height, 1, "件数1")
  assert_eq(calc(0).list_height, 1, "件数0でも1行は出す")
end)

test("一覧の高さが上限 10 で頭打ちになる", function()
  assert_eq(calc(20).list_height, 10, "件数20")
end)

test("狭い画面ではプレビューを出さない", function()
  local l = calc(1, 60, 45)
  assert_eq(l.preview_visible, false, "プレビュー非表示")
  assert_eq(l.preview_width, 0, "プレビュー幅")
end)

test("狭い画面では 1 カラムへフォールバックする", function()
  local l = calc(1, 60, 45)
  assert_eq(l.total_width, 52, "既存の columns - 8")
  assert_eq(l.left_width, l.total_width, "左カラムが全幅")
  assert_eq(l.gap, 0, "ギャップなし")
end)

test("プレビューが左カラム全体の高さを覆う", function()
  local l = calc(3)
  assert_eq(l.preview_height, l.list_height + l.draft_height + 2, "枠の外側が揃う高さ")
  assert_eq(l.preview_col, l.col + l.left_width + l.gap, "プレビューは左カラムの右隣")
  assert_eq(l.preview_row, l.row, "プレビューは一覧と同じ行から始まる")
end)

test("件数が増えたらプレビューも伸びる", function()
  local before = calc(1)
  local after = calc(3)
  assert_true(after.preview_height > before.preview_height, "プレビュー高さが伸びる")
  assert_eq(
    after.preview_height - before.preview_height,
    after.list_height - before.list_height,
    "伸び幅は一覧と同じ"
  )
end)

test("下書きは一覧の 2 行下に置かれる", function()
  local l = calc(3)
  assert_eq(l.draft_row, l.row + l.list_height + 2, "下書きの行")
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if not ok then
    error(string.format("FAILED [%s]\n%s", t.display, err))
  end
  print("ok - " .. t.display)
end
print("agent_term preview layout tests passed")
