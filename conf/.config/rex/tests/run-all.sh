#!/usr/bin/env bash
# Rex 連携（conf/.config/rex）のテストをまとめて実行する。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TEST_DIR="${REPO_ROOT}/conf/.config/rex/tests"
cd "$REPO_ROOT"

failed=()

if ! command -v nvim >/dev/null 2>&1; then
  echo "Error: nvim not found. Run inside 'nix develop .#ci'." >&2
  exit 1
fi

# ローカルの ~/.config/nvim を読み込まないよう XDG_CONFIG_HOME を空にする
SANDBOX_HOME="$(mktemp -d)"
trap 'rm -rf "$SANDBOX_HOME"' EXIT

for test_file in "${TEST_DIR}"/test_*.lua; do
  name="$(basename "$test_file")"
  printf '\n=== %s ===\n' "$name"
  XDG_CONFIG_HOME="$SANDBOX_HOME" nvim --headless -u NONE -l "$test_file" || failed+=("$name")
done

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\nREX TESTS FAILED: %s\n' "${failed[*]}" >&2
  exit 1
fi
