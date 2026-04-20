#!/usr/bin/env bash

# Switch tmux sessions in creation order.
# Usage: switch-session.sh next|prev

set -euo pipefail

direction="${1:-next}"

current=$(tmux display-message -p '#S')

# session_created (Unix timestamp) でソートしたセッション名一覧
sessions=$(tmux list-sessions -F '#{session_created} #{session_name}' \
    | sort -n \
    | awk '{print $2}')

case "$direction" in
    next)
        target=$(echo "$sessions" | awk -v c="$current" '
            found { print; exit }
            $0 == c { found = 1 }
        ')
        # 末尾なら先頭へラップ
        [ -z "$target" ] && target=$(echo "$sessions" | head -n 1)
        ;;
    prev)
        target=$(echo "$sessions" | awk -v c="$current" '
            $0 == c { print prev; exit }
            { prev = $0 }
        ')
        # 先頭なら末尾へラップ
        [ -z "$target" ] && target=$(echo "$sessions" | tail -n 1)
        ;;
    *)
        echo "Usage: $0 next|prev" >&2
        exit 1
        ;;
esac

tmux switch-client -t "$target"
