#!/usr/bin/env bash
# SessionEnd hook: remove session ID file
set -euo pipefail

pid=$PPID
while [ "$pid" != "1" ]; do
  cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
  case "$cmd" in
    claude|claude.ex|claude.exe)
      rm -f "/tmp/claude-sessions/$pid"
      exit 0
      ;;
  esac
  pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
done
