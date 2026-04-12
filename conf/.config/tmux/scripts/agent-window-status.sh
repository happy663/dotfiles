#!/bin/bash
# Update tmux window status with agent state
# Usage: agent-window-status.sh <status>
#   status: running | waiting | done | error | idle

PANE_ID="${TMUX_PANE:-}"
if [ -z "$PANE_ID" ]; then
  exit 0
fi

STATUS="$1"
DIR_NAME=$(basename "$PWD")

case "$STATUS" in
  running|waiting|done|error)
    tmux set-option -w -t "$PANE_ID" automatic-rename off 2>/dev/null
    tmux set-option -w -t "$PANE_ID" @agent-status "$STATUS" 2>/dev/null
    tmux rename-window -t "$PANE_ID" "$DIR_NAME"
    ;;
  idle)
    tmux set-option -wu -t "$PANE_ID" @agent-status 2>/dev/null
    tmux set-option -w -t "$PANE_ID" automatic-rename on 2>/dev/null
    ;;
esac
