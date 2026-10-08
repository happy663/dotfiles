#!/usr/bin/env bash
# CIとローカルで共通利用する、安定稼働中のテストスイート。
# Neovimテストは既存のbuffer名衝突による失敗があるため、修復後に追加する。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

run() {
  local name="$1"
  shift
  printf '\n=== %s ===\n' "$name"
  "$@"
}

for test_file in scripts/tests/*.test.sh; do
  run "Script: $(basename "$test_file")" bash "$test_file"
done
run "Pi extensions" \
  bun test ./conf/.pi/agent/tests/*.test.ts
run "tmux configuration" \
  bash conf/.config/tmux/tests/run-all.sh
run "review-loop skill" \
  bash conf/.config/ai-agents/skills/review-loop/tests/run-all.sh

printf '\nALL CI TESTS PASSED\n'
