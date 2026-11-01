#!/usr/bin/env bash
set -euo pipefail

# Copy wezterm configuration to the correct location
# Windows用 (WSL 上で実行する)
cp -r ~/.config/wezterm /mnt/c/Users/toyama/.config
