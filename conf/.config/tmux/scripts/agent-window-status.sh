#!/bin/bash
# Update the Agent state shown in tmux (window-status / pane-border).
# Shared by Claude Code hooks (settings.json) and Codex hooks (hooks.json).
#
# 状態の語彙（正の定義は issue #315。pi 側の実装は
# conf/.pi/agent/extensions/tmux-status.ts。語彙を変えるときは両方直すこと）:
#   running   作業中
#   blocked   許可・質問で中断している
#   idle      応答が終わって次の指示を待っている
#   error     失敗して終わった
#   （未設定）Agent がいない
#
# Usage: agent-window-status.sh <command>
#   running | blocked | idle | error   状態を設定する
#   resume                             作業が再開したので running に戻す
#   clear                              状態を解除する

set -uo pipefail

PANE_ID="${TMUX_PANE:-}"
if [ -z "$PANE_ID" ]; then
  exit 0
fi

# タイトル生成のために入れ子で起動された Agent は無視する。
# agent-pane-task.sh は CLAUDE_TASK_RENAMER=1 claude -p / CODEX_TASK_RENAMER=1
# codex exec を呼ぶが、その子プロセスは親と同じ TMUX_PANE を持つため、
# ガードしないと入れ子側のフックが親ペインの状態を上書きしてしまう。
if [ -n "${CLAUDE_TASK_RENAMER:-}" ] || [ -n "${CODEX_TASK_RENAMER:-}" ]; then
  exit 0
fi

set_state() {
  tmux set-option -w -t "$PANE_ID" automatic-rename off 2>/dev/null
  tmux set-option -p -t "$PANE_ID" @agent-status "$1" 2>/dev/null
}

case "${1:-}" in
  running | blocked | idle | error)
    set_state "$1"
    tmux rename-window -t "$PANE_ID" "$(basename "$PWD")" 2>/dev/null
    ;;
  resume)
    # PostToolUse から呼ばれる。ツールが動いた＝実際には走っているので、
    # blocked のまま居座るのを防ぐ。状態が空のペイン（Agent がいない）は触らない。
    current=$(tmux display-message -p -t "$PANE_ID" "#{@agent-status}" 2>/dev/null)
    if [ -n "$current" ] && [ "$current" != "running" ]; then
      set_state running
    fi
    ;;
  clear)
    tmux set-option -pu -t "$PANE_ID" @agent-status 2>/dev/null
    tmux set-option -w -t "$PANE_ID" automatic-rename on 2>/dev/null
    ;;
esac
