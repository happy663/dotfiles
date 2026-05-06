#!/usr/bin/env bash
# Claude Code の settings.json を base / local の 2 ファイルに分割管理する。
#
# base.json: dotfiles にコミット
# local.json: ~/.claude/settings.local.json (マシン固有)
#
# 振り分けるキーは下記 2 種類:
#   generic_local_keys:      スクリプト内定数
#   CLAUDE_EXTRA_LOCAL_KEYS: .env に jq path 配列で記述
#
# Commands:
#   pull: ~/.claude/settings.json → base.json + local.json
#   push: base.json + local.json → ~/.claude/settings.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BASE_PATH="${DOTFILES_DIR}/conf/.claude/settings.base.json"
EXAMPLE_PATH="${DOTFILES_DIR}/conf/.claude/settings.local.example.json"
ENV_PATH="${DOTFILES_DIR}/.env"
ACTIVE_PATH="${HOME}/.claude/settings.json"
LOCAL_PATH="${HOME}/.claude/settings.local.json"

load_env() {
    if [[ -f "$ENV_PATH" ]]; then
        set -a
        # shellcheck disable=SC1090
        . "$ENV_PATH"
        set +a
    fi
}

JQ_FILTERS='
def generic_local_keys:
    [
        ["model"],
        ["effortLevel"],
        ["permissions", "defaultMode"]
    ];

def all_local_keys:
    generic_local_keys + $extra_local_keys;

def filter_del_local:
    delpaths(all_local_keys | sort);

def filter_pick_local:
    . as $root
    | reduce all_local_keys[] as $p ({};
        if ($root | getpath($p)) != null
        then setpath($p; $root | getpath($p))
        else . end);
'

run_filter() {
    local source_path="$1"
    local entrypoint="$2"
    jq --argjson extra_local_keys "${CLAUDE_EXTRA_LOCAL_KEYS:-[]}" \
       "${JQ_FILTERS}
${entrypoint}" "$source_path"
}

write_atomic() {
    local target="$1"
    local content="$2"
    local tmp
    tmp="$(mktemp "${target}.XXXXXX")"
    printf '%s\n' "$content" > "$tmp"
    mv "$tmp" "$target"
}

cmd_pull() {
    if [[ ! -f "$ACTIVE_PATH" ]]; then
        echo "Error: $ACTIVE_PATH not found" >&2
        exit 1
    fi
    if [[ -L "$ACTIVE_PATH" ]]; then
        echo "Error: $ACTIVE_PATH is still a symlink. Run 'make claude-push' first." >&2
        exit 1
    fi
    load_env

    local base_content local_content
    base_content="$(run_filter "$ACTIVE_PATH" "filter_del_local")"
    local_content="$(run_filter "$ACTIVE_PATH" "filter_pick_local")"

    write_atomic "$BASE_PATH" "$base_content"
    write_atomic "$LOCAL_PATH" "$local_content"

    echo "✓ pulled:"
    echo "  base  → $BASE_PATH"
    echo "  local → $LOCAL_PATH"
    echo
    echo "--- review base.json diff before committing ---"
    git -C "$DOTFILES_DIR" --no-pager diff -- conf/.claude/settings.base.json || true
}

cmd_push() {
    if [[ ! -f "$BASE_PATH" ]]; then
        echo "Error: $BASE_PATH not found" >&2
        exit 1
    fi
    load_env

    mkdir -p "$(dirname "$ACTIVE_PATH")"

    if [[ ! -f "$LOCAL_PATH" ]]; then
        if [[ -f "$EXAMPLE_PATH" ]]; then
            cp "$EXAMPLE_PATH" "$LOCAL_PATH"
            echo "→ initialized $LOCAL_PATH from example"
        else
            echo '{}' > "$LOCAL_PATH"
            echo "→ initialized $LOCAL_PATH as empty object"
        fi
    fi

    if [[ -L "$ACTIVE_PATH" ]]; then
        rm "$ACTIVE_PATH"
    fi

    local merged
    merged="$(jq -s '.[0] * .[1]' "$BASE_PATH" "$LOCAL_PATH")"
    write_atomic "$ACTIVE_PATH" "$merged"

    echo "✓ pushed → $ACTIVE_PATH"
}

usage() {
    cat <<EOF
Usage: $0 {pull|push}
  pull   active settings.json から base.json と local.json を再構築
  push   base.json と local.json をマージして active settings.json を上書き
EOF
}

case "${1:-}" in
    pull) cmd_pull ;;
    push) cmd_push ;;
    -h|--help|help) usage ;;
    *) usage; exit 1 ;;
esac
