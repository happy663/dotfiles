#!/usr/bin/env bash
# pi (pi-coding-agent) の settings.json を base / local の 2 ファイルに分割管理する。
#
# base.json: dotfiles にコミット (宣言的に管理したい設定: packages 等)
# local.json: ~/.pi/agent/settings.local.json (マシン固有・runtime で変わる設定)
#
# 振り分けるキーは下記 2 種類:
#   conf/.pi/agent/managed-paths.json: 管理パス (jq path 配列)
#   PI_EXTRA_LOCAL_KEYS:               .env に jq path 配列で記述
#
# なぜ symlink ではなく生成物にするか:
#   pi は settings.json を runtime で書き換える (model/theme 切替, バージョンアップ等)。
#   settings.json を symlink で dotfiles 実体に向けると、runtime 書き換えが毎回 git diff になる。
#   そのため settings.json は「base + local のマージ生成物 (gitignore)」とし、
#   dotfiles 側には base.json (宣言的) だけを置く。
#
# Commands:
#   pull: ~/.pi/agent/settings.json → base.json + local.json
#   push: base.json + local.json → ~/.pi/agent/settings.json
#
# 実処理は lib/settings-merge.sh に集約している (claude-settings.sh と共通)。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SM_DOTFILES_DIR="${DOTFILES_DIR}"
SM_BASE_PATH="${DOTFILES_DIR}/conf/.pi/agent/settings.base.json"
SM_EXAMPLE_PATH="${DOTFILES_DIR}/conf/.pi/agent/settings.local.example.json"
SM_MANAGED_PATHS_FILE="${DOTFILES_DIR}/conf/.pi/agent/managed-paths.json"
SM_ENV_PATH="${DOTFILES_DIR}/.env"
SM_ACTIVE_PATH="${HOME}/.pi/agent/settings.json"
SM_LOCAL_PATH="${HOME}/.pi/agent/settings.local.json"
SM_EXTRA_KEYS_VAR="PI_EXTRA_LOCAL_KEYS"
SM_PUSH_HINT="make pi-push"
SM_BASE_REL_PATH="conf/.pi/agent/settings.base.json"

# shellcheck source=lib/settings-merge.sh
. "${SCRIPT_DIR}/lib/settings-merge.sh"

sm_main "$@"
