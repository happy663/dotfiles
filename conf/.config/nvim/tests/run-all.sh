#!/usr/bin/env bash
# Neovim (Lua) テストをまとめて実行する。
#
# 各テストはプラグインに依存しないよう package.loaded で依存をスタブしている。
# そのため -u NONE で起動し、runtimepath にリポジトリの nvim 設定だけを足す。
# テストの一部は vim.fn.getcwd() から lua/ を解決するので、リポジトリルートで実行する。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
NVIM_CONFIG="${REPO_ROOT}/conf/.config/nvim"

if ! command -v nvim >/dev/null 2>&1; then
  echo "Error: nvim not found. Run inside 'nix develop .#ci'." >&2
  exit 1
fi

# どの neovim で検証したかをログに残す（CI とローカルで版がずれたときの手がかり）。
printf 'nvim: %s (%s)\n' "$(nvim --version | head -1)" "$(command -v nvim)"

# ローカルの ~/.config/nvim は runtimepath 経由で読み込まれ、リポジトリ側の
# ファイルを隠してしまう。CI には存在しないため、XDG_CONFIG_HOME を空にして揃える。
SANDBOX_HOME="$(mktemp -d)"
trap 'rm -rf "$SANDBOX_HOME"' EXIT

cd "$REPO_ROOT"

failed=()
for test_file in "${NVIM_CONFIG}"/tests/test_*.lua; do
  name="$(basename "$test_file")"
  printf '\n=== %s ===\n' "$name"
  if ! XDG_CONFIG_HOME="$SANDBOX_HOME" nvim --headless -u NONE \
    --cmd "set runtimepath+=${NVIM_CONFIG}" -l "$test_file"; then
    failed+=("$name")
  fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\nNVIM TESTS FAILED: %s\n' "${failed[*]}" >&2
  exit 1
fi

printf '\nALL NVIM TESTS PASSED\n'
