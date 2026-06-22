#!/usr/bin/env bash
# SessionStart hook: record session ID keyed by claude PID
set -euo pipefail

mkdir -p /tmp/claude-sessions

pid=$PPID
while [ "$pid" != "1" ]; do
  cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
  case "$cmd" in
    claude|claude.ex|claude.exe)
      echo "$CLAUDE_CODE_SESSION_ID" > "/tmp/claude-sessions/$pid"
      exit 0
      ;;
  esac
  pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
done
