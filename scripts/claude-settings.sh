#!/usr/bin/env bash
# Claude Code の settings.json を base / local の 2 ファイルに分割管理する。
#
# base.json: dotfiles にコミット
# local.json: ~/.claude/settings.local.json (マシン固有)
#
# 振り分けるキーは下記 2 種類:
#   conf/.claude/presets/managed-paths.json: 管理パス (jq path 配列)
#   CLAUDE_EXTRA_LOCAL_KEYS:                 .env に jq path 配列で記述
#
# Commands:
#   pull: ~/.claude/settings.json → base.json + local.json
#   push: base.json + local.json → ~/.claude/settings.json
#
# 実処理は lib/settings-merge.sh に集約している (pi-settings.sh と共通)。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SM_DOTFILES_DIR="${DOTFILES_DIR}"
SM_BASE_PATH="${DOTFILES_DIR}/conf/.claude/settings.base.json"
SM_EXAMPLE_PATH="${DOTFILES_DIR}/conf/.claude/settings.local.example.json"
SM_MANAGED_PATHS_FILE="${DOTFILES_DIR}/conf/.claude/presets/managed-paths.json"
SM_ENV_PATH="${DOTFILES_DIR}/.env"
SM_ACTIVE_PATH="${HOME}/.claude/settings.json"
SM_LOCAL_PATH="${HOME}/.claude/settings.local.json"
SM_EXTRA_KEYS_VAR="CLAUDE_EXTRA_LOCAL_KEYS"
SM_PUSH_HINT="make claude-push"
SM_BASE_REL_PATH="conf/.claude/settings.base.json"

# shellcheck source=lib/settings-merge.sh
. "${SCRIPT_DIR}/lib/settings-merge.sh"

sm_main "$@"
