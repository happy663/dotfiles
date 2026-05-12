#!/usr/bin/env bash
# run-codex.sh
# Codex CLI を非対話モードで呼び出す薄いラッパー。
#
# 使い方:
#   echo "<prompt>" | ./run-codex.sh <output_file>
#   ./run-codex.sh <output_file> < prompt.md
#
# 終了コード:
#   codex の終了コードをそのまま返す
#
# 環境変数:
#   CODEX_MODEL          (任意) 利用モデル名。未指定なら codex 既定
#   CODEX_TIMEOUT_SEC    (任意) タイムアウト秒数。未指定なら無制限
#   CODEX_SANDBOX        (任意) サンドボックスモード。既定 read-only
#                              （レビュー用途なのでファイル変更は不要）
set -euo pipefail

OUTPUT="${1:?usage: run-codex.sh <output_file>}"

cmd=(codex exec --sandbox "${CODEX_SANDBOX:-read-only}" --output-last-message "$OUTPUT")
[[ -n "${CODEX_MODEL:-}" ]] && cmd+=(--model "$CODEX_MODEL")

# stdin に prompt が流れてくる前提。 - は明示的にstdinを指定する記法。
cmd+=(-)

if [[ -n "${CODEX_TIMEOUT_SEC:-}" ]]; then
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "${CODEX_TIMEOUT_SEC}" "${cmd[@]}"
    elif command -v timeout >/dev/null 2>&1; then
        timeout "${CODEX_TIMEOUT_SEC}" "${cmd[@]}"
    else
        echo "run-codex: timeout/gtimeout not found, ignoring CODEX_TIMEOUT_SEC" >&2
        "${cmd[@]}"
    fi
else
    "${cmd[@]}"
fi
