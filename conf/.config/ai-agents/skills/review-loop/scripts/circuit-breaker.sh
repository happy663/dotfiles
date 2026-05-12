#!/usr/bin/env bash
# circuit-breaker.sh
# レビューループを継続して良いか判定する。
#
# 入力:
#   $REVIEW_LOOP_DIR/state.json
#   $REVIEW_LOOP_DIR/rounds/round-N/classification.json (各ラウンドの分類結果)
#     形式: { "applied_count": <int>, "items": [{"id": "...", "status": "..."}, ...] }
#
# 出力:
#   exit 0  → 継続
#   exit 1  → 停止。停止理由を1行で stdout に出す
#     理由: max_rounds / no_progress / persistent_disagreement
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./state.sh
. "$SCRIPT_DIR/state.sh"

current=$(state_get round)
max=$(state_get max_rounds)
current=${current:-1}
max=${max:-3}

# 1) max_rounds 超過
if (( current > max )); then
    echo "max_rounds (current=$current, max=$max)"
    exit 1
fi

# 完了済みラウンド = current - 1
completed=$(( current - 1 ))
(( completed <= 0 )) && exit 0  # まだ完了ラウンドなし → 継続

# ラウンド N の classification.json から applied_count を取得
_applied() {
    local n="$1"
    local f="$REVIEW_LOOP_DIR/rounds/round-$n/classification.json"
    [[ -f "$f" ]] || { echo 0; return; }
    jq -r '.applied_count // 0' "$f"
}

# ラウンド N の残存指摘ID集合（status=remaining）
_remaining_ids() {
    local n="$1"
    local f="$REVIEW_LOOP_DIR/rounds/round-$n/classification.json"
    [[ -f "$f" ]] || { printf ''; return; }
    jq -r '.items[]? | select(.status=="remaining") | .id' "$f" | sort -u
}

# 2) persistent_disagreement: 同一指摘IDが直近3ラウンド連続で残存
#    ※ no_progress より先に判定する（より具体的な状況のため停止理由として優先）
if (( completed >= 3 )); then
    r1=$(_remaining_ids "$completed")
    r2=$(_remaining_ids $((completed - 1)))
    r3=$(_remaining_ids $((completed - 2)))
    if [[ -n "$r1" && -n "$r2" && -n "$r3" ]]; then
        common=$(comm -12 <(printf '%s\n' "$r1") <(printf '%s\n' "$r2") | \
                 comm -12 - <(printf '%s\n' "$r3"))
        if [[ -n "$common" ]]; then
            echo "persistent_disagreement (ids: $(echo "$common" | tr '\n' ',' | sed 's/,$//'))"
            exit 1
        fi
    fi
fi

# 3) no_progress: 直近2ラウンド連続で applied=0
if (( completed >= 2 )); then
    a1=$(_applied "$completed")
    a2=$(_applied $((completed - 1)))
    if [[ "$a1" -eq 0 && "$a2" -eq 0 ]]; then
        echo "no_progress (rounds $((completed-1))-$completed: applied=0,0)"
        exit 1
    fi
fi

exit 0
