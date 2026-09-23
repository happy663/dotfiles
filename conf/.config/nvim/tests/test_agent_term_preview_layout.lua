-- ピッカーのレイアウト計算（picker/layout.lua）のテスト。
-- ウィンドウを開かないので、純粋に寸法だけを検証する。
--
-- 期待する形（横並び）:
--   ┌──────────────────────────┐
--   │        preview           │  上段: 全幅
--   ├───────────┬──────────────┤
--   │  prompt   │    agent     │  下段: 左に下書き、右に一覧
--   └───────────┴──────────────┘
--
-- ピッカー全体の幅は画面の 8 割、高さは画面いっぱい（罫線込みで収まる上限）。
--
--   cd <repo root>
--   nvim --headless -l conf/.config/nvim/tests/test_agent_term_preview_layout.lua
-- このリポジトリの設定は $HOME 配下へ symlink されるため、Neovim の runtimepath には
-- ~/.config/nvim（= main のコピー）が入っている。worktree でテストを走らせると
-- そちらが先に解決されて main のコードをテストしてしまうので、worktree を先頭に置く。
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/conf/.config/nvim")

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

test("ピッカー全体の幅は画面の 8 割に制限される", function()
  local l = calc(1)
  assert_eq(l.total_width, 155, "194 桁の 8 割")
  assert_eq(l.col, 19, "左右の余白")
end)

test("プレビューは上段に全幅で置かれる", function()
  local l = calc(1)
  assert_true(l.preview_visible, "広い画面ではプレビューを出す")
  assert_eq(l.preview_width, l.total_width, "プレビューが全幅")
  assert_eq(l.preview_col, l.col, "左端はピッカーと揃う")
  assert_eq(l.preview_row, l.row, "上端はピッカーと揃う")
end)

test("下段は prompt と agent の横並びになる", function()
  local l = calc(1)
  assert_eq(l.draft_row, l.list_row, "同じ行に並ぶ")
  assert_eq(l.draft_col, l.col, "prompt が左")
  assert_eq(l.list_col, l.col + l.draft_width + l.gap, "agent が右")
  assert_eq(l.draft_width + l.gap + l.list_width, l.total_width, "下段の合計幅")
  assert_eq(l.draft_height, l.list_height, "左右の高さが揃う")
  assert_eq(l.list_height, l.bottom_height, "下段の高さに揃う")
end)

test("prompt が 3 割、agent が 7 割になる", function()
  local l = calc(1)
  assert_eq(l.draft_width, 46, "155 の 3 割")
  assert_eq(l.list_width, 107, "残りからギャップを引いた分")
end)

test("prompt は最低幅を下回らない", function()
  local l = calc(1, 100, 45)
  assert_eq(l.total_width, 80, "100 桁の 8 割")
  assert_eq(l.draft_width, 30, "最低幅")
  assert_eq(l.list_width, 48, "残りは agent へ")
  assert_true(l.preview_visible, "プレビューは残る")
end)

test("下段の高さは下書きの高さを下回らない", function()
  assert_eq(calc(1).bottom_height, 8, "件数1")
  assert_eq(calc(3).bottom_height, 8, "件数3")
  assert_eq(calc(0).bottom_height, 8, "件数0でも下書きの高さを確保する")
end)

test("下段の高さは一覧の件数に追従し、上限で頭打ちになる", function()
  assert_eq(calc(12).bottom_height, 10, "件数12は上限10")
  assert_eq(calc(20).bottom_height, 10, "件数20も上限10")
end)

test("ピッカーの高さは画面いっぱいになる", function()
  assert_eq(calc(1, 194, 45).picker_height, 43, "45 行 - 罫線 2")
  assert_eq(calc(1, 194, 20).picker_height, 18, "20 行 - 罫線 2")
end)

test("プレビューは下段の 2 行上までを占める", function()
  local l = calc(1)
  assert_eq(l.preview_height, 33, "ピッカー43 - 下段8 - 罫線2")
  assert_eq(l.draft_row, l.row + l.preview_height + 2, "罫線 2 行を挟む")
  assert_eq(l.draft_row, 36, "45 行画面の下段の行")
end)

test("Agent が増えると下段が伸び、プレビューが縮む", function()
  local few = calc(1)
  local many = calc(20)
  assert_eq(many.bottom_height, 10, "下段が伸びる")
  assert_eq(many.preview_height, few.preview_height - 2, "プレビューが縮む")
  assert_eq(many.picker_height, few.picker_height, "ピッカー全体の高さは画面で決まる")
end)

test("18 人以上の Agent でもプレビューが最低高さを保つ", function()
  local l = calc(18)
  assert_true(l.preview_visible, "プレビューは出る: " .. tostring(l.preview_height))
  assert_true(l.preview_height >= 6, "最低高さ: " .. tostring(l.preview_height))
end)

test("横並びの一覧が狭すぎるなら prompt と agent を縦積みにする", function()
  local l = calc(1, 55, 45)
  assert_eq(l.total_width, 44, "55 桁の 8 割")
  assert_true(l.preview_visible == false, "プレビューは出さない")
  assert_eq(l.preview_width, 0, "プレビュー幅")
  assert_eq(l.draft_width, l.total_width, "prompt が全幅")
  assert_eq(l.list_width, l.total_width, "agent も全幅")
  assert_eq(l.list_row, l.draft_row + l.draft_height + 2, "prompt の下に agent")
  assert_eq(l.list_col, l.col, "左端は揃う")
end)

test("縦積みでは一覧の高さが件数に追従する", function()
  assert_eq(calc(3, 55, 45).list_height, 3, "件数3")
  assert_eq(calc(20, 55, 45).list_height, 10, "件数20は上限10")
  assert_eq(calc(3, 55, 45).draft_height, 8, "下書きは設定値のまま")
end)

test("低い画面ではプレビューを出さず下段だけを出す", function()
  local l = calc(1, 194, 10)
  assert_eq(l.preview_visible, false, "プレビュー非表示")
  assert_eq(l.preview_width, 0, "プレビュー幅")
  assert_eq(l.bottom_height, 8, "下段の高さ")
  assert_true(l.list_width > 0, "横並びは維持する: " .. tostring(l.list_width))
  assert_eq(l.draft_row, l.list_row, "下段は横並びのまま")
end)

for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if not ok then
    error(string.format("FAILED [%s]\n%s", t.display, err))
  end
  print("ok - " .. t.display)
end
print("agent_term preview layout tests passed")
