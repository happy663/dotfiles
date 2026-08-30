#!/usr/bin/env bash
# test_hide_session.sh: hide-session.sh の前セッション選択ロジック（prev_session）のテスト。
# 仕様を固定する:
#   1. 作成順リストから、現在セッションの直前の要素を返す
#   2. 現在セッションが先頭なら末尾へラップする
#   3. 現在セッションがリストに無ければ exit 1（呼び出し側でエラー扱い）
#   4. リストが1要素のみなら自分自身を返す（呼び出し側で「他に可視セッションなし」を判定する材料）
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_assert.sh"

# 実装ファイルを source する（関数定義のみ。main は BASH_SOURCE ガードで走らない）
HIDE_SCRIPT="$SCRIPT_DIR/../scripts/hide-session.sh"
if [[ ! -f "$HIDE_SCRIPT" ]]; then
    assert_fail "hide-session.sh が存在しない（${HIDE_SCRIPT}）"
    report_assertions
    exit 1
fi
# set -euo pipefail が source で有効になるとコマンド置換の非0が即終了するため、テスト中は解除
set +euo pipefail
source "$HIDE_SCRIPT"
# hide-session.sh が再度 set -euo pipefail を有効化するため再解除
set +euo pipefail

# 3要素リスト（作成順）
LIST3="floorCPM
dotfiles
sazabi"

# --- 1. 通常ケース: dotfiles の前は floorCPM ---
actual=$(printf '%s\n' "$LIST3" | prev_session "dotfiles")
assert_eq "prev of middle (dotfiles -> floorCPM)" "floorCPM" "$actual"

# --- 1b. 末尾の前はその直前 ---
actual=$(printf '%s\n' "$LIST3" | prev_session "sazabi")
assert_eq "prev of last (sazabi -> dotfiles)" "dotfiles" "$actual"

# --- 2. 先頭は末尾へラップ ---
actual=$(printf '%s\n' "$LIST3" | prev_session "floorCPM")
assert_eq "prev of first wraps (floorCPM -> sazabi)" "sazabi" "$actual"

# --- 3. リストに無い現在名は exit 1 ---
rc=0
if actual=$(printf '%s\n' "$LIST3" | prev_session "nonexistent") 2>/dev/null; then
    rc=0
else
    rc=1
fi
assert_eq "prev of unknown exits nonzero" "1" "$rc"

# --- 4. 1要素のみなら自分自身 ---
actual=$(printf '%s\n' "dotfiles" | prev_session "dotfiles")
assert_eq "prev of only session is itself" "dotfiles" "$actual"

# --- 4b. 1要素リストで未知の名前も exit 1 ---
rc=0
if printf '%s\n' "dotfiles" | prev_session "unknown" >/dev/null 2>&1; then
    rc=0
else
    rc=1
fi
assert_eq "prev of unknown in one-item list exits nonzero" "1" "$rc"

report_assertions