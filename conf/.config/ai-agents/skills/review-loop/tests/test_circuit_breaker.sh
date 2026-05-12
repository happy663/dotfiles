#!/usr/bin/env bash
# circuit-breaker.sh のユニットテスト
#
# 規約:
#   state.round = "次に開始するラウンド番号"。完了済み = state.round - 1。
#
# 停止条件（チェック順）:
#   1. max_rounds: state.round > max_rounds
#   2. persistent_disagreement: 直近3ラウンドの remaining ID に共通要素あり
#   3. no_progress: 直近2ラウンドが連続で applied=0
#
# テストは各条件が排他的に発火するよう seed を組む。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$SCRIPT_DIR/tests/_assert.sh"

TMP=$(mktemp -d)
trap 'report_assertions || exit 1; rm -rf "$TMP"' EXIT
export REVIEW_LOOP_DIR="$TMP/review-loop"
# shellcheck source=../scripts/state.sh
. "$SCRIPT_DIR/scripts/state.sh"
TARGET="$SCRIPT_DIR/scripts/circuit-breaker.sh"

reset_state() {
    rm -rf "$REVIEW_LOOP_DIR"
    mkdir -p "$REVIEW_LOOP_DIR/rounds"
    state_init
}

seed_round() {
    local n="$1" applied="$2" remaining_ids="$3"
    local d
    d=$(state_round_dir "$n")
    local items="[]"
    if [[ -n "$remaining_ids" ]]; then
        items=$(echo "$remaining_ids" | tr ',' '\n' | jq -R '{id: ., status: "remaining"}' | jq -s .)
    fi
    jq -n --argjson applied "$applied" --argjson items "$items" \
        '{applied_count: $applied, items: $items}' > "$d/classification.json"
}

run_cb() {
    "$TARGET" 2>&1
    return $?
}

test_cb_continue() {
    reset_state
    state_set round 2
    state_set max_rounds 3
    seed_round 1 2 "a"   # 1ラウンド完了、進捗あり
    local out code
    out=$(run_cb); code=$?
    assert_eq "1ラウンド完了で進捗あり → 継続" 0 "$code"
}

test_cb_max_rounds() {
    reset_state
    state_set round 4   # 3ラウンド完了、4ラウンド目に入ろうとしている
    state_set max_rounds 3
    seed_round 1 1 ""
    seed_round 2 1 ""
    seed_round 3 1 ""
    local out code
    out=$(run_cb); code=$?
    assert_eq "max超過 → 停止" 1 "$code"
    assert_contains "停止理由 max_rounds" "$out" "max_rounds"
}

test_cb_no_progress() {
    reset_state
    state_set round 3   # 2ラウンド完了
    state_set max_rounds 5
    # 直近2ラウンド applied=0、ID は別物にして persistent と被らないようにする
    seed_round 1 0 "x"
    seed_round 2 0 "y"
    local out code
    out=$(run_cb); code=$?
    assert_eq "連続2回 applied=0 → 停止" 1 "$code"
    assert_contains "停止理由 no_progress" "$out" "no_progress"
}

test_cb_persistent_disagreement() {
    reset_state
    state_set round 4   # 3ラウンド完了
    state_set max_rounds 5
    # 各ラウンド applied>0 で進捗はあるが、stuck だけは3回連続で残存
    seed_round 1 2 "stuck,a"
    seed_round 2 1 "stuck,b"
    seed_round 3 1 "stuck,c"
    local out code
    out=$(run_cb); code=$?
    assert_eq "同一ID3ラウンド残存 → 停止" 1 "$code"
    assert_contains "停止理由 persistent_disagreement" "$out" "persistent_disagreement"
}

test_cb_continue
test_cb_max_rounds
test_cb_no_progress
test_cb_persistent_disagreement
