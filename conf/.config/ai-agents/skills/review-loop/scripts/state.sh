#!/usr/bin/env bash
# state.sh
# review-loopの状態管理ユーティリティ。source して関数を使う想定。
#
# 前提環境変数:
#   REVIEW_LOOP_DIR  状態保存ディレクトリ（プロジェクトの .claude/review-loop/）
#
# 公開関数:
#   state_init               state.json を初期化（存在すれば何もしない）
#   state_set <key> <value>  値を保存（JSON文字列として）
#   state_get <key>          値を取得（未設定なら空文字）
#   state_round_dir <N>      ラウンドNのディレクトリを mkdir -p して返す
set -u

: "${REVIEW_LOOP_DIR:?REVIEW_LOOP_DIR must be set}"

_state_file() {
    printf '%s/state.json' "$REVIEW_LOOP_DIR"
}

state_init() {
    mkdir -p "$REVIEW_LOOP_DIR/rounds"
    local f
    f=$(_state_file)
    [[ -f "$f" ]] || echo '{}' > "$f"
}

state_get() {
    local key="$1"
    local f
    f=$(_state_file)
    [[ -f "$f" ]] || { printf ''; return 0; }
    # null / 未定義は空文字に正規化
    local v
    v=$(jq -r --arg k "$key" '.[$k] // empty' "$f")
    printf '%s' "$v"
}

state_set() {
    local key="$1" value="$2"
    state_init
    local f tmp
    f=$(_state_file)
    tmp=$(mktemp)
    # 数値として解釈できればnumber、そうでなければstringとして保存
    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        jq --arg k "$key" --argjson v "$value" '.[$k] = $v' "$f" > "$tmp"
    else
        jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$f" > "$tmp"
    fi
    mv "$tmp" "$f"
}

state_round_dir() {
    local n="$1"
    local d="$REVIEW_LOOP_DIR/rounds/round-$n"
    mkdir -p "$d"
    printf '%s' "$d"
}
