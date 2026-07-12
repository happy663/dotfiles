#!/usr/bin/env bash
# Claude Code hook: capture the first user prompt on UserPromptSubmit (submit mode),
# then generate the tmux pane task title on response completion (stop mode).
#
# Split into two phases so the title appears at "response complete" timing (matching
# Codex), while still reading the clean .prompt field from UserPromptSubmit (avoids
# transcript parsing noise from command/skill messages).
#
# Resume handling: when a title is already cached for the session-id, no LLM call
# runs; instead the cached title is restored onto the current pane if missing, so
# resuming the same session in a different pane/window still shows the title.
#
# Recursion guard: CLAUDE_TASK_RENAMER breaks re-entry when agent-pane-task.sh
# calls `claude -p`, which itself triggers UserPromptSubmit/Stop.
#
# Usage: claude-pane-task.sh <submit|stop>
#   submit: save the first prompt to /tmp/claude-prompts/<session_id>
#   stop:   read the saved prompt and generate the title

set -uo pipefail

MODE="${1:-}"

if [ -n "${CLAUDE_TASK_RENAMER:-}" ]; then
  exit 0
fi

if [ -z "${TMUX_PANE:-}" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

# Stop ペイロードで session_id が取れない場合は transcript_path のファイル名から復元。
if [ -z "$SESSION_ID" ]; then
  TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
  if [ -n "$TRANSCRIPT" ]; then
    SESSION_ID=$(basename "$TRANSCRIPT" | sed 's/\.jsonl$//')
  fi
fi

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

TASK_CACHE="/tmp/agent-pane-tasks/$SESSION_ID"
PROMPT_CACHE_DIR="/tmp/claude-prompts"
PROMPT_CACHE="$PROMPT_CACHE_DIR/$SESSION_ID"

# キャッシュ済みタイトルを現在のペインに復元する（LLM 呼ばない、差分時のみ更新）。
restore_pane_task() {
  local title="$1"
  [ -z "$title" ] && return
  local current
  current=$(tmux display-message -p -t "$TMUX_PANE" "#{@pane-task}" 2>/dev/null)
  if [ "$current" != "$title" ]; then
    tmux set-option -pt "$TMUX_PANE" @pane-task "$title" 2>/dev/null
  fi
}

# タイトル生成済みのセッション（resume 等）なら、現在のペインに復元して終了。
if [ -f "$TASK_CACHE" ]; then
  restore_pane_task "$(cat "$TASK_CACHE" 2>/dev/null)"
  exit 0
fi

case "$MODE" in
  submit)
    PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty')
    [ -z "$PROMPT" ] && exit 0
    # 初回プロンプト固定: 既存のプロンプトキャッシュがあれば上書きしない。
    if [ ! -f "$PROMPT_CACHE" ]; then
      mkdir -p "$PROMPT_CACHE_DIR" 2>/dev/null
      printf '%s' "$PROMPT" > "$PROMPT_CACHE"
    fi
    ;;
  stop)
    [ -f "$PROMPT_CACHE" ] || exit 0
    PROMPT=$(cat "$PROMPT_CACHE")
    [ -z "$PROMPT" ] && exit 0
    export CLAUDE_TASK_RENAMER=1
    SCRIPT="${HOME}/.config/tmux/scripts/agent-pane-task.sh"
    [ -x "$SCRIPT" ] && "$SCRIPT" "$SESSION_ID" "$PROMPT" claude
    ;;
esac
