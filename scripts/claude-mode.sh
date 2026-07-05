#!/usr/bin/env bash
# Claude Code の動作モードを preset で切替する。
#
# Modes:
#   glm      GLM5.2 (z.ai) 接続モード
#   fable    素の Claude + Fable
#   opus47   素の Claude + Opus 4.7 (1M)
#
# 処理:
#   1. preset を envsubst で展開
#   2. 既存 ~/.claude/settings.local.json から managed-paths.json のパスを削除
#   3. preset を deep-merge して書き戻し
#   4. claude-settings.sh push で base とマージして active settings を再生成
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PRESETS_DIR="${DOTFILES_DIR}/conf/.claude/presets"
MANAGED_PATHS_FILE="${PRESETS_DIR}/managed-paths.json"
ENV_PATH="${DOTFILES_DIR}/.env"
LOCAL_PATH="${HOME}/.claude/settings.local.json"
SETTINGS_SCRIPT="${SCRIPT_DIR}/claude-settings.sh"

usage() {
    cat <<EOF
Usage: $0 {glm|fable|opus47}
  glm      GLM5.2 (z.ai) 接続モードに切替
  fable    素の Claude + Fable モードに切替
  opus47   素の Claude + Opus 4.7 (1M) モードに切替
EOF
}

load_env() {
    if [[ -f "$ENV_PATH" ]]; then
        set -a
        # shellcheck disable=SC1090
        . "$ENV_PATH"
        set +a
    fi
}

require_command() {
    local cmd="$1" hint="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' not found. $hint" >&2
        exit 1
    fi
}

# preset のリーフパスを jq path 配列で列挙する。
# 出力例: [["model"],["env","ANTHROPIC_AUTH_TOKEN"], ...]
preset_leaf_paths() {
    local preset_json="$1"
    printf '%s' "$preset_json" | jq -c '[paths(scalars)]'
}

# preset のリーフパスが全部 managed-paths.json に載っているか検証する。
validate_preset_against_managed() {
    local preset_json="$1"
    local leaves
    leaves="$(preset_leaf_paths "$preset_json")"

    local missing
    missing="$(jq -c -n \
        --argjson leaves "$leaves" \
        --slurpfile managed "$MANAGED_PATHS_FILE" \
        '$leaves - $managed[0]')"

    if [[ "$missing" != "[]" ]]; then
        echo "Error: preset に managed-paths.json に無いパスが含まれています: $missing" >&2
        echo "       $MANAGED_PATHS_FILE を更新してから再実行してください。" >&2
        exit 1
    fi
}

apply_preset() {
    local mode="$1"
    local preset_file="${PRESETS_DIR}/${mode}.json"

    if [[ ! -f "$preset_file" ]]; then
        echo "Error: preset $preset_file not found" >&2
        exit 1
    fi
    if [[ ! -f "$MANAGED_PATHS_FILE" ]]; then
        echo "Error: $MANAGED_PATHS_FILE not found" >&2
        exit 1
    fi

    # envsubst の展開対象を CLAUDE_GLM_AUTH_TOKEN のみに絞る（他の $ を巻き添えにしない）
    local preset_json
    preset_json="$(envsubst '$CLAUDE_GLM_AUTH_TOKEN' < "$preset_file")"

    # envsubst のプレースホルダが未解決のまま残っていないか
    if printf '%s' "$preset_json" | grep -q '\${'; then
        echo "Error: preset に未展開のプレースホルダが残っています。" >&2
        echo "$preset_json" | grep '\${' >&2
        exit 1
    fi

    validate_preset_against_managed "$preset_json"

    # 既存 local を読み込み（無ければ {}）
    local existing
    if [[ -f "$LOCAL_PATH" ]]; then
        existing="$(cat "$LOCAL_PATH")"
    else
        existing='{}'
    fi

    # existing から managed パスを削除 → preset を deep-merge
    local merged
    merged="$(jq -n \
        --argjson existing "$existing" \
        --argjson preset "$preset_json" \
        --slurpfile managed "$MANAGED_PATHS_FILE" \
        '($existing | delpaths($managed[0] | sort)) * $preset')"

    mkdir -p "$(dirname "$LOCAL_PATH")"
    local tmp
    tmp="$(mktemp "${LOCAL_PATH}.XXXXXX")"
    printf '%s\n' "$merged" > "$tmp"
    mv "$tmp" "$LOCAL_PATH"

    echo "✓ mode=${mode}: updated $LOCAL_PATH"
}

main() {
    local mode="${1:-}"
    case "$mode" in
        glm|fable|opus47) ;;
        -h|--help|help) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac

    require_command jq "Install via nix or brew."
    require_command envsubst "Install via 'nix profile install nixpkgs#gettext' or 'brew install gettext'."

    load_env

    if [[ "$mode" == "glm" ]]; then
        if [[ -z "${CLAUDE_GLM_AUTH_TOKEN:-}" ]]; then
            echo "Error: CLAUDE_GLM_AUTH_TOKEN が .env に定義されていません。" >&2
            echo "       ${ENV_PATH} に 'CLAUDE_GLM_AUTH_TOKEN=xxxxx' を追加してください。" >&2
            exit 1
        fi
    fi

    apply_preset "$mode"

    # active settings を再生成
    bash "$SETTINGS_SCRIPT" push
}

main "$@"
