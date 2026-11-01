#!/usr/bin/env bash
# settings.json を base / local の 2 ファイルに分割管理する共通ロジック。
#
# claude-settings.sh / pi-settings.sh は本ファイルを source し、
# 下記の SM_* 変数を設定してから sm_main "$@" を呼ぶ。
#
# 呼び出し側が設定する変数:
#   SM_DOTFILES_DIR        dotfiles リポジトリのルート
#   SM_BASE_PATH           dotfiles にコミットする base.json
#   SM_EXAMPLE_PATH        local.json の雛形
#   SM_MANAGED_PATHS_FILE  local に切り出すキー (jq path 配列) の一覧
#   SM_ENV_PATH            .env のパス
#   SM_ACTIVE_PATH         実際に読まれる settings.json
#   SM_LOCAL_PATH          マシン固有の local.json
#   SM_EXTRA_KEYS_VAR      追加 local キーを格納した環境変数の名前
#   SM_PUSH_HINT           エラー時に案内する make target
#   SM_BASE_REL_PATH       pull 後に git diff するリポジトリ相対パス

SM_JQ_FILTERS='
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

# 呼び出し側の設定漏れを早く検出する
sm_require_vars() {
    local var
    for var in SM_DOTFILES_DIR SM_BASE_PATH SM_EXAMPLE_PATH SM_MANAGED_PATHS_FILE \
        SM_ENV_PATH SM_ACTIVE_PATH SM_LOCAL_PATH SM_EXTRA_KEYS_VAR \
        SM_PUSH_HINT SM_BASE_REL_PATH; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: ${var} is not set (settings-merge.sh requires configuration)" >&2
            exit 1
        fi
    done
}

sm_load_env() {
    if [[ -f "$SM_ENV_PATH" ]]; then
        set -a
        # shellcheck disable=SC1090
        . "$SM_ENV_PATH"
        set +a
    fi
}

sm_run_filter() {
    local source_path="$1"
    local entrypoint="$2"
    if [[ ! -f "$SM_MANAGED_PATHS_FILE" ]]; then
        echo "Error: $SM_MANAGED_PATHS_FILE not found" >&2
        exit 1
    fi
    jq --argjson extra_local_keys "${!SM_EXTRA_KEYS_VAR:-[]}" \
        --slurpfile managed_paths_file "$SM_MANAGED_PATHS_FILE" \
        '($managed_paths_file[0]) as $managed_paths | '"${SM_JQ_FILTERS}
${entrypoint}" "$source_path"
}

sm_write_atomic() {
    local target="$1"
    local content="$2"
    local tmp
    tmp="$(mktemp "${target}.XXXXXX")"
    printf '%s\n' "$content" >"$tmp"
    mv "$tmp" "$target"
}

sm_cmd_pull() {
    if [[ ! -f "$SM_ACTIVE_PATH" ]]; then
        echo "Error: $SM_ACTIVE_PATH not found" >&2
        exit 1
    fi
    if [[ -L "$SM_ACTIVE_PATH" ]]; then
        echo "Error: $SM_ACTIVE_PATH is still a symlink. Run '$SM_PUSH_HINT' first." >&2
        exit 1
    fi
    sm_load_env

    local base_content local_content
    base_content="$(sm_run_filter "$SM_ACTIVE_PATH" "filter_del_local")"
    local_content="$(sm_run_filter "$SM_ACTIVE_PATH" "filter_pick_local")"

    sm_write_atomic "$SM_BASE_PATH" "$base_content"
    sm_write_atomic "$SM_LOCAL_PATH" "$local_content"

    echo "✓ pulled:"
    echo "  base  → $SM_BASE_PATH"
    echo "  local → $SM_LOCAL_PATH"
    echo
    echo "--- review base.json diff before committing ---"
    git -C "$SM_DOTFILES_DIR" --no-pager diff -- "$SM_BASE_REL_PATH" || true
}

sm_cmd_push() {
    if [[ ! -f "$SM_BASE_PATH" ]]; then
        echo "Error: $SM_BASE_PATH not found" >&2
        exit 1
    fi
    sm_load_env

    mkdir -p "$(dirname "$SM_ACTIVE_PATH")"

    if [[ ! -f "$SM_LOCAL_PATH" ]]; then
        if [[ -f "$SM_EXAMPLE_PATH" ]]; then
            cp "$SM_EXAMPLE_PATH" "$SM_LOCAL_PATH"
            echo "→ initialized $SM_LOCAL_PATH from example"
        else
            echo '{}' >"$SM_LOCAL_PATH"
            echo "→ initialized $SM_LOCAL_PATH as empty object"
        fi
    fi

    if [[ -L "$SM_ACTIVE_PATH" ]]; then
        rm "$SM_ACTIVE_PATH"
    fi

    local merged
    merged="$(jq -s '.[0] * .[1]' "$SM_BASE_PATH" "$SM_LOCAL_PATH")"
    sm_write_atomic "$SM_ACTIVE_PATH" "$merged"

    echo "✓ pushed → $SM_ACTIVE_PATH"
}

sm_usage() {
    cat <<EOF
Usage: $(basename "$0") {pull|push}
  pull   active settings.json から base.json と local.json を再構築
  push   base.json と local.json をマージして active settings.json を上書き
EOF
}

sm_main() {
    sm_require_vars
    case "${1:-}" in
        pull) sm_cmd_pull ;;
        push) sm_cmd_push ;;
        -h | --help | help) sm_usage ;;
        *)
            sm_usage
            exit 1
            ;;
    esac
}
