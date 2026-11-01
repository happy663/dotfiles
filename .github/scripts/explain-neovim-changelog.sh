#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_TEMP:?RUNNER_TEMP is required}"

stage='Pi のインストール失敗'
report_failure() {
  printf '%s\n' "$stage" > ./ci-logs/neovim-status.txt
}
trap report_failure ERR
if [[ -z "${OPENCODE_API_KEY:-}" ]]; then
  stage='OPENCODE_API_KEY Secret 未設定'
  report_failure
  exit 1
fi
# CI is pinned independently from nixpkgs pi-coding-agent. When updating, compare
# the nixpkgs version in flake.lock and recheck these CLI flags and the model catalog.
PI_VERSION='1.4.0'
PI_MODEL='opencode-go/deepseek-v4.1-flash'

# Isolate CI from personal Pi settings, credentials, packages and instructions.
export PI_CODING_AGENT_DIR="$RUNNER_TEMP/neovim-pi-agent"
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0
mkdir -p "$PI_CODING_AGENT_DIR"
# Install outside the checkout so no package files enter the update PR.
npm install --prefix "$RUNNER_TEMP/neovim-pi" --ignore-scripts --no-audit --no-fund \
  "@earendil-works/pi-coding-agent@$PI_VERSION"

# Resolve the exact model against the pinned bundled catalog before inference.
stage='モデル解決失敗（Pi の固定カタログにモデルがありません）'
"$RUNNER_TEMP/neovim-pi/node_modules/.bin/pi" \
  --no-tools --no-session --no-extensions --no-mcp --no-skills \
  --no-prompt-templates --no-context-files --no-approve --offline --list-models > "$RUNNER_TEMP/neovim-pi-models.txt"
awk -v provider="${PI_MODEL%%/*}" -v model="${PI_MODEL#*/}" \
  '$1 == provider && $2 == model { found=1 } END { exit !found }' \
  "$RUNNER_TEMP/neovim-pi-models.txt"

stage='AI生成失敗（認証・利用枠・APIエラー等）'
if timeout 180s "$RUNNER_TEMP/neovim-pi/node_modules/.bin/pi" \
  --print --model "$PI_MODEL" \
  --no-tools --no-session --no-extensions --no-mcp --no-skills \
  --no-prompt-templates --no-context-files --no-approve --offline \
  < ./ci-logs/neovim-input.md > ./ci-logs/neovim-ai.tmp.md; then
  :
else
  result=$?
  if [[ "$result" == 124 || "$result" == 137 ]]; then
    stage='AI推論タイムアウト（180秒）'
  fi
  report_failure
  exit "$result"
fi

stage='AI出力が空'
test -s ./ci-logs/neovim-ai.tmp.md
mv ./ci-logs/neovim-ai.tmp.md ./ci-logs/neovim-ai.md
