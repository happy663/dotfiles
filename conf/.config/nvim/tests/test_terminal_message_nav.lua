package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local nav = require("core.terminal_message_nav")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

-- OSC 133 のマーカー行の種別判定
-- pi はユーザーメッセージ先頭行を背景色で塗るため「空白のみ・非空」になる
assert_eq(nav.classify_marker_line(""), "assistant", "空行は応答マーカー")
assert_eq(nav.classify_marker_line(nil), "assistant", "nil は応答マーカー")
assert_eq(nav.classify_marker_line(string.rep(" ", 80)), "user", "空白のみの行はユーザー")
assert_eq(nav.classify_marker_line(" こんにちは"), "assistant", "本文行はユーザーではない")

-- 前後のマーカー探索
local list = { 10, 40, 90 }
assert_eq(nav.neighbor(list, 0, 1), 10, "先頭より上から次へ")
assert_eq(nav.neighbor(list, 10, 1), 40, "現在位置より次へ")
assert_eq(nav.neighbor(list, 11, 1), 40, "マーカー間から次へ")
assert_eq(nav.neighbor(list, 90, 1), nil, "末尾より先は無い")
assert_eq(nav.neighbor(list, 90, -1), 40, "現在位置より前へ")
assert_eq(nav.neighbor(list, 39, -1), 10, "マーカー間から前へ")
assert_eq(nav.neighbor(list, 10, -1), nil, "先頭より前は無い")
assert_eq(nav.neighbor({}, 10, 1), nil, "空リストは nil")

-- カーソルが属するブロックの範囲
local start, stop = nav.block_range(list, 45, 120)
assert_eq(start, 40, "ブロック開始")
assert_eq(stop, 89, "ブロック終了は次のマーカー手前")
start, stop = nav.block_range(list, 5, 120)
assert_eq(start, 10, "先頭より上では最初のブロック")
assert_eq(stop, 39, "先頭ブロックの終了")
start, stop = nav.block_range(list, 90, 120)
assert_eq(start, 90, "末尾ブロックの開始")
assert_eq(stop, 120, "末尾ブロックは最終行まで")
start, stop = nav.block_range({}, 1, 10)
assert_eq(start, nil, "マーカーが無ければ nil")
assert_eq(stop, nil, "マーカーが無ければ nil")

-- ジャンプ先の決定（前方に次が無ければ最新＝最終行へ）
assert_eq(nav.jump_target(list, 45, 1, 120), 90, "前方の次マーカーへ")
assert_eq(nav.jump_target(list, 90, 1, 120), 120, "前方に次が無ければ最終行へ")
assert_eq(nav.jump_target(list, 5, 1, 120), 10, "先頭より上からは最初のマーカーへ")
assert_eq(nav.jump_target(list, 45, -1, 120), 40, "後方の前マーカーへ")
assert_eq(nav.jump_target(list, 5, -1, 120), nil, "後方に前が無ければ移動しない")
assert_eq(nav.jump_target({}, 1, 1, 120), 120, "マーカーが無くても最新へ")
assert_eq(nav.jump_target({}, 1, -1, 120), nil, "マーカーが無く後方なら移動しない")

-- ブロック末尾の空行除去
assert_eq(nav.trim_block_end({ "a", "b", "", "   " }, 1, 4), 2, "末尾の空行を除去")
assert_eq(nav.trim_block_end({ "a", "b  " }, 1, 2), 2, "末尾に本文があればそのまま")
assert_eq(nav.trim_block_end({ "a", "", "" }, 1, 3), 1, "全て空行なら開始行で止まる")

-- バックエンド判定（種類別）
-- ターン: OSC133 のユーザーマーカー > ❯ プロンプト行 > OSC133 マーカー
assert_eq(nav.detect_turn_backend(true, true, true), "osc133", "ユーザーマーカーがあれば osc133")
assert_eq(
  nav.detect_turn_backend(false, true, true),
  "cli-claude",
  "通常ターミナルの ❯ プロンプトは Claude 経路"
)
assert_eq(nav.detect_turn_backend(false, true, false), "osc133", "❯ が無ければ osc133 にフォールバック")
assert_eq(nav.detect_turn_backend(false, false, true), "cli-claude", "OSC133 が無くても ❯ で動く")
assert_eq(nav.detect_turn_backend(false, false, false), nil, "どちらも無ければ判定なし")

-- メッセージ: ⏺ ブロック > OSC133 の応答マーカー
assert_eq(nav.detect_message_backend(true, true), "cli-claude", "⏺ があれば Claude 経路")
assert_eq(nav.detect_message_backend(false, true), "osc133", "⏺ が無ければ osc133")
assert_eq(nav.detect_message_backend(false, false), nil, "どちらも無ければ判定なし")

print("terminal_message_nav tests passed")
