#!/usr/bin/env bash
# pi (pi-coding-agent) の settings.json を base / local の 2 ファイルに分割管理する。
#
# base.json: dotfiles にコミット (宣言的に管理したい設定: packages 等)
# local.json: ~/.pi/agent/settings.local.json (マシン固有・runtime で変わる設定)
#
# 振り分けるキーは下記 2 種類:
#   managed-paths.json:   dotfiles 内の jq path 配列
#   PI_EXTRA_LOCAL_KEYS:  .env に jq path 配列で記述
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
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BASE_PATH="${DOTFILES_DIR}/conf/.pi/agent/settings.base.json"
EXAMPLE_PATH="${DOTFILES_DIR}/conf/.pi/agent/settings.local.example.json"
MANAGED_PATHS_FILE="${DOTFILES_DIR}/conf/.pi/agent/managed-paths.json"
ENV_PATH="${DOTFILES_DIR}/.env"
ACTIVE_PATH="${HOME}/.pi/agent/settings.json"
LOCAL_PATH="${HOME}/.pi/agent/settings.local.json"

load_env() {
    if [[ -f "$ENV_PATH" ]]; then
        set -a
        # shellcheck disable=SC1090
        . "$ENV_PATH"
        set +a
    fi
}

JQ_FILTERS='
def all_local_keys:
    $managed_paths + $extra_local_keys;

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
    if [[ ! -f "$MANAGED_PATHS_FILE" ]]; then
        echo "Error: $MANAGED_PATHS_FILE not found" >&2
        exit 1
    fi
    jq --argjson extra_local_keys "${PI_EXTRA_LOCAL_KEYS:-[]}" \
       --slurpfile managed_paths_file "$MANAGED_PATHS_FILE" \
       '($managed_paths_file[0]) as $managed_paths | '"${JQ_FILTERS}
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
        echo "Error: $ACTIVE_PATH is still a symlink. Run 'make pi-push' first." >&2
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
    git -C "$DOTFILES_DIR" --no-pager diff -- conf/.pi/agent/settings.base.json || true
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
