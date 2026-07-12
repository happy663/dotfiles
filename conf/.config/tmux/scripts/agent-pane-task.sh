#!/bin/bash
# Generate an Agent task title from the first user prompt and set it as a tmux pane option.
# Usage: agent-pane-task.sh <session_id> <prompt> <agent_kind>
#   agent_kind: claude | codex   (decides which CLI is used to summarize; codex falls back to claude)
#
# Behavior:
# - Per session-id, the title is generated only once (first prompt). 2nd+ prompts are skipped.
# - resume keeps the same session-id -> title preserved. fork gets a new session-id -> new title.
# - Title format: English, lowercase kebab-case, <= 5 words, prefixed with '#' (e.g. #fix-tmux-window-name).

set -uo pipefail

SESSION_ID="${1:-}"
PROMPT="${2:-}"
AGENT_KIND="${3:-claude}"

if [ -z "$SESSION_ID" ] || [ -z "$PROMPT" ]; then
  exit 0
fi

PANE_ID="${TMUX_PANE:-}"
if [ -z "$PANE_ID" ]; then
  exit 0
fi

CACHE_DIR="/tmp/agent-pane-tasks"
mkdir -p "$CACHE_DIR" 2>/dev/null
CACHE_FILE="$CACHE_DIR/$SESSION_ID"

# session-id ごとに1回だけ生成（2回目以降スキップ）。
# 既存キャッシュがあれば、resume 先ペインへタイトルを復元して終了（LLM 呼ばない）。
if [ -f "$CACHE_FILE" ]; then
  CACHED_TITLE=$(cat "$CACHE_FILE" 2>/dev/null)
  if [ -n "$CACHED_TITLE" ]; then
    CURRENT=$(tmux display-message -p -t "$PANE_ID" "#{@pane-task}" 2>/dev/null)
    if [ "$CURRENT" != "$CACHED_TITLE" ]; then
      tmux set-option -pt "$PANE_ID" @pane-task "$CACHED_TITLE" 2>/dev/null || true
    fi
  fi
  exit 0
fi

# 並列呼び出しで二重生成しないよう、生成前に空キャッシュを置く。
: > "$CACHE_FILE"

# Truncate the prompt to keep the LLM input small.
TRUNCATED=$(printf '%s' "$PROMPT" | head -c 500)

SUMMARY_PROMPT="Summarize the following task into a concise title. Rules: at most 5 words, English, lowercase kebab-case (words joined by single hyphens), no punctuation, no quotes, no explanation, no trailing period. Output ONLY the title on a single line.

---
$TRUNCATED"

generate_title() {
  local kind="$1"
  case "$kind" in
    codex)
      if command -v codex >/dev/null 2>&1; then
        CODEX_TASK_RENAMER=1 codex exec "$SUMMARY_PROMPT" 2>/dev/null || true
        return
      fi
      ;;
  esac
  # default / fallback: claude
  if command -v claude >/dev/null 2>&1; then
    CLAUDE_TASK_RENAMER=1 claude -p "$SUMMARY_PROMPT" 2>/dev/null || true
  fi
}

RAW=$(generate_title "$AGENT_KIND")

# クリーンアップ: 小文字化 → 英数とハイフン以外をハイフンに → トークン化して最初の塊 → 40字制限
TITLE=$(printf '%s' "$RAW" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -c 'a-z0-9\n' '-' \
  | grep -oE '[a-z0-9][a-z0-9-]*' \
  | head -1 \
  | sed 's/--*/-/g; s/^-//; s/-$//' \
  | cut -c1-40)

if [ -z "$TITLE" ]; then
  # 生成失敗時は空キャッシュのまま終了（次回もスキップさせ、無駄な再生成を防ぐ）。
  exit 0
fi

TITLE="#$TITLE"

# pane option を設定（pane-border / window-status の表示側で参照）。
tmux set-option -pt "$PANE_ID" @pane-task "$TITLE" 2>/dev/null || true

# キャッシュを確定（resume 時の再生成防止）。
printf '%s' "$TITLE" > "$CACHE_FILE"
