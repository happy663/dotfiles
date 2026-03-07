#!/usr/bin/env bash

set -euo pipefail

TARGET_INDEX="${SEND_REVIEW_RESULT_TARGET:-1}"
DEFAULT_SERVER="$HOME/.cache/nvim/server.pipe"

if [ "$#" -gt 0 ]; then
  MESSAGE="$*"
else
  MESSAGE=$(cat <<'EOF'
## レビュー結果

### 総評
LGTM
EOF
)
fi

can_connect() {
  local server="$1"
  local out
  [ -n "$server" ] || return 1
  out=$(nvr --servername "$server" --remote-expr '1' 2>/dev/null || true)
  [ "$out" = "1" ]
}

SERVER_CANDIDATES=()

if [ -n "${SEND_REVIEW_RESULT_SERVER:-}" ]; then
  SERVER_CANDIDATES+=("${SEND_REVIEW_RESULT_SERVER}")
fi

if [ -n "${NVIM:-}" ]; then
  SERVER_CANDIDATES+=("${NVIM}")
fi

SERVER_CANDIDATES+=("${DEFAULT_SERVER}")

SERVER=""
for candidate in "${SERVER_CANDIDATES[@]}"; do
  if can_connect "$candidate"; then
    SERVER="$candidate"
    break
  fi
done

if [ -z "$SERVER" ]; then
  while IFS= read -r candidate; do
    if can_connect "$candidate"; then
      SERVER="$candidate"
      break
    fi
  done < <(nvr --serverlist 2>/dev/null || true)
fi

if [ -z "$SERVER" ]; then
  echo "send_review_result: nvr server not found" >&2
  exit 1
fi

PAYLOAD=$(jq -cn \
  --argjson target "$TARGET_INDEX" \
  --arg command "$MESSAGE" \
  '{"target": $target, "command": $command}')

# Vimscript single-quoted string requires apostrophes to be doubled.
PAYLOAD_VIM=${PAYLOAD//\'/\'\'}

EXPR="luaeval('require(\"terminal_bridge\").external_send(_A)', '$PAYLOAD_VIM')"

RESULT=$(nvr --servername "$SERVER" --remote-expr "$EXPR" 2>&1 || true)

if ! printf '%s' "$RESULT" | grep -q '"success":[[:space:]]*true'; then
  echo "send_review_result: failed to send via server: $SERVER" >&2
  printf '%s\n' "$RESULT" >&2
  exit 1
fi

printf '%s\n' "$RESULT"
