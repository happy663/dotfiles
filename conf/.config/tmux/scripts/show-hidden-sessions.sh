#!/usr/bin/env bash
# Show hidden sessions (@hidden=on) in a native menu and restore the selected one.
# Used by `prefix R` in tmux.conf. Hidden sessions stay alive (detached) in tmux.

set -euo pipefail

# @hidden=on のセッション名一覧（作成順。session-tabs.sh / switch-session.sh と同じ判定）
names=()
while IFS= read -r name; do
    names+=("$name")
done < <(tmux list-sessions -F '#{session_created} #{session_name} #{?#{==:#{@hidden},on},1,0}' | sort -n | awk '$3 == 1 {print $2}')

if [ "${#names[@]}" -eq 0 ]; then
    tmux display-message "No hidden sessions"
    exit 0
fi

# display-menu: "label" key command の3つ組を繰り返す
# 選択したセッションの @hidden を外し、縦リスト（session-tabs.sh）を再描画する。
args=(-T "Hidden sessions (restore)")
for name in "${names[@]}"; do
    args+=("Restore $name" "" "run-shell 'tmux set-option -t \"$name\" @hidden off && ~/.config/tmux/session-tabs.sh'")
done
# キャンセル（Escape でも閉じられる）
args+=("Cancel" "q" "")

tmux display-menu "${args[@]}"