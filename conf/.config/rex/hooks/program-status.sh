#!/usr/bin/env bash
# Claude Code の状態を OSC 7501（Program Status Protocol）で端末へ伝える。
# 仕様: https://www.superlogical.com/rex/docs/build/program-status
#
# Rex の中で動いているとき（REX_SESSION があるとき）だけ書き込み、それ以外は何もしない。
# Claude Code が Neovim の :terminal 内にいる場合は、Neovim 側
# （conf/.config/rex/nvim/program_status.lua）が受け取ってバッファごとの id を付け、Rex へ転送する。
#
# Usage: program-status.sh <command>   （stdin に hook の JSON を受け取る）
#   working        作業中（UserPromptSubmit / PostToolUse）
#   notification   通知の種類に応じて blocked にする（Notification）
#   done           応答が終わった（Stop）
#   error          失敗して終わった（StopFailure）
#   clear          状態を消す（SessionEnd）

set -uo pipefail

input="$(cat)"

if [ -z "${REX_SESSION:-}" ]; then
  exit 0
fi

# タイトル生成のために入れ子で起動された Agent は無視する
# （conf/.config/tmux/scripts/agent-window-status.sh と同じ理由）。
if [ -n "${CLAUDE_TASK_RENAMER:-}" ] || [ -n "${CODEX_TASK_RENAMER:-}" ] || [ -n "${PI_TASK_RENAMER:-}" ]; then
  exit 0
fi

b64() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

# Claude Code は hook を制御端末なしで起動するため /dev/tty は使えない。
# 祖先プロセスをたどり、最初に見つかった端末（Claude Code 本体の端末）へ書き込む。
find_tty() {
  local pid=$$ tty i=0
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] && [ $i -lt 10 ]; do
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    case "$tty" in
      "" | "?" | "??") ;;
      *)
        echo "/dev/${tty}"
        return 0
        ;;
    esac
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    i=$((i + 1))
  done
  return 1
}

title="$(b64 "$(basename "$PWD")")"
common="app=claude-code:title=${title}"

case "${1:-}" in
  working | done | error)
    body="state=$1:${common}"
    ;;
  clear)
    body="state=clear"
    ;;
  notification)
    type=$(printf '%s' "$input" | jq -r '.notification_type // ""' 2>/dev/null)
    # 制御文字は仕様で禁止されているので空白にし、長さも抑える
    message=$(printf '%s' "$input" | jq -r '(.message // "") | gsub("[[:cntrl:]]"; " ") | .[:500]' 2>/dev/null)
    case "$type" in
      idle_prompt) exit 0 ;;
      permission_prompt) kind=":kind=permission" ;;
      elicitation_dialog) kind=":kind=question" ;;
      *) kind="" ;;
    esac
    body="state=blocked${kind}:${common}"
    if [ -n "$message" ]; then
      body="${body}:msg=$(b64 "$message")"
    fi
    ;;
  *)
    exit 0
    ;;
esac

dest="${REX_PROGRAM_STATUS_TTY:-}"
if [ -z "$dest" ]; then
  dest="$(find_tty)" || exit 0
fi

printf '\033]7501;%s\033\\' "$body" >"$dest" 2>/dev/null
exit 0
