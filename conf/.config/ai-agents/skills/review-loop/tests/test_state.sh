#!/usr/bin/env bash
# state.sh のユニットテスト
# state.sh は ~/.claude/skills/review-loop/scripts/state.sh で source されることを想定。
# REVIEW_LOOP_DIR を作業ディレクトリ（=各プロジェクトの .claude/review-loop/）として使う。
#
# 仕様:
#   - state_init: state.json を空のJSONで作成（既存なら何もしない）
#   - state_set <key> <value>: JSONに値を書き込む（jq 経由）
#   - state_get <key>: 値を返す。未設定なら空文字
#   - state_round_dir <N>: ラウンドNのディレクトリパスを返す（mkdir -p込み）
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$SCRIPT_DIR/tests/_assert.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

export REVIEW_LOOP_DIR="$TMP/review-loop"
# shellcheck source=../scripts/state.sh
. "$SCRIPT_DIR/scripts/state.sh"

test_state() {
    state_init
    assert_true "state.json が作成されている" "[[ -f \"$REVIEW_LOOP_DIR/state.json\" ]]"

    # set/get round-trip
    state_set round 1
    assert_eq "数値を読み戻せる" "1" "$(state_get round)"

    state_set scope_hash "abc123"
    assert_eq "文字列を読み戻せる" "abc123" "$(state_get scope_hash)"

    # 未設定キーは空
    assert_eq "未設定キーは空" "" "$(state_get nonexistent)"

    # round_dir
    local d
    d=$(state_round_dir 1)
    assert_true "round1 ディレクトリ作成" "[[ -d \"$d\" ]]"
    assert_eq "round_dir のパス" "$REVIEW_LOOP_DIR/rounds/round-1" "$d"

    # state_init は冪等
    state_init
    assert_eq "init後も値が残る" "1" "$(state_get round)"
}

test_state
