#!/usr/bin/env bash
# Hide the current session (@hidden on) and switch to the previous visible session.
# Used by `prefix H` in tmux.conf.
# 縦リスト（session-tabs.sh）からだけ除外し、セッション自体はデタッチ状態で生存させる。
# 復帰は `prefix R`（show-hidden-sessions.sh）または `tmux attach -t <name>`。

set -euo pipefail

# --- pure helpers (sourceable for tests) ------------------------------------

# stdin: 作成順の可視セッション名（1行1つ）
# $1:    現在のセッション名
# stdout: 1つ前のセッション名（先頭なら末尾へラップ）
# exit:  0=見つかった / 1=リストに無い
prev_session() {
    local current="$1"
    local -a names=()
    local name i
    # 一覧を先に全部読み込む（末尾ラップに最後の要素が必要なため）
    while IFS= read -r name; do
        names+=("$name")
    done
    for ((i = 0; i < ${#names[@]}; i++)); do
        if [ "${names[$i]}" = "$current" ]; then
            if [ "$i" -eq 0 ]; then
                # 先頭: 末尾へラップ
                printf '%s\n' "${names[${#names[@]} - 1]}"
            else
                printf '%s\n' "${names[$i - 1]}"
            fi
            return 0
        fi
    done
    return 1
}

# --- tmux actions -------------------------------------------------------------

# 可視セッション（@hidden=on 以外）を作成順で列挙
visible_sessions() {
    tmux list-sessions \
        -F '#{session_created} #{session_name} #{?#{==:#{@hidden},on},1,0}' \
        | sort -n \
        | awk '$3 != 1 {print $2}'
}

# --- main -----------------------------------------------------------------------

# 現在セッションを隠す（@hidden on + 縦リスト再描画）。実際の切り替えは main が行う。
# stdout: 切り替え先のセッション名（作成順で1つ前の可視セッション）
# exit: 0=成功 / 1=中止（メッセージ表示済み）
hide_session() {
    local current="$1" target

    # 現在セッションが可視一覧に無い（既に隠されている等）場合は何もしない。
    if ! target=$(visible_sessions | prev_session "$current"); then
        tmux display-message "No visible session to switch to" >/dev/null 2>&1 || true
        return 1
    fi
    # 可視セッションが自分だけ。隠すと移動先がなくなるので中止する。
    if [ "$target" = "$current" ]; then
        tmux display-message "Cannot hide the only visible session" >/dev/null 2>&1 || true
        return 1
    fi

    tmux set-option -t "$current" @hidden on
    ~/.config/tmux/session-tabs.sh
    printf '%s\n' "$target"
}

main() {
    local current target

    current=$(tmux display-message -p '#S')
    if ! target=$(hide_session "$current"); then
        exit 1
    fi
    tmux switch-client -t "$target"
}

# source された場合は main を実行しない（テストから関数だけを読み込むため）
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi