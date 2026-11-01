#!/usr/bin/env bash
set -euo pipefail

: "${OPENCODE_API_KEY:?Set the OPENCODE_API_KEY Actions secret}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"

# Isolate CI from personal Pi settings, credentials, packages and instructions.
export PI_CODING_AGENT_DIR="$RUNNER_TEMP/neovim-pi-agent"
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0
mkdir -p "$PI_CODING_AGENT_DIR"
# Install outside the checkout so no package files enter the update PR.
npm install --prefix "$RUNNER_TEMP/neovim-pi" --ignore-scripts --no-audit --no-fund \
  @earendil-works/pi-coding-agent@1.4.0

timeout 180s "$RUNNER_TEMP/neovim-pi/node_modules/.bin/pi" \
  --print --model opencode-go/deepseek-v4.1-flash \
  --no-tools --no-session --no-extensions --no-mcp --no-skills \
  --no-prompt-templates --no-context-files --no-approve --offline \
  < ./ci-logs/neovim-input.md > ./ci-logs/neovim-ai.tmp.md

test -s ./ci-logs/neovim-ai.tmp.md
mv ./ci-logs/neovim-ai.tmp.md ./ci-logs/neovim-ai.md
