#!/usr/bin/env bash
# herdr のプラグインを入れる（issue #351）。何度実行してもよい。
#
# herdr のプラグインは `herdr plugin install` / `link` で ~/.config/herdr に登録される（宣言的に管理できない）ため、
# 使うプラグインをここに並べて、まとめて入れる。キーの割り当ては conf/.config/herdr/config.toml にある。
#
# Usage: scripts/herdr-plugins.sh [--yes] [dotfiles-dir]
#   --yes  GitHub のプラグインを確認なしで入れる（端末から実行しないとき herdr が要求する）
set -euo pipefail

install_flags=()
if [[ "${1:-}" == "--yes" ]]; then
  install_flags+=(--yes)
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${1:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if ! command -v herdr >/dev/null 2>&1; then
  echo "Error: herdr not found. Run make nix-apply-home first." >&2
  exit 1
fi

installed="$(herdr plugin list 2>/dev/null || true)"

# GitHub から入れるプラグイン: "<owner/repo> <ref> <plugin id>"
github_plugins=(
  # C-h/j/k/l で nvim のウィンドウと herdr のペインをまたいで移動する
  "aimdevlee/herdr-nvim-nav v1.0.0 herdr-nvim-nav"
)

for entry in "${github_plugins[@]}"; do
  read -r repo ref id <<<"$entry"
  if grep -q "$id" <<<"$installed"; then
    echo "skip: $id (installed)"
    continue
  fi
  echo "install: $repo@$ref"
  herdr plugin install "$repo" --ref "$ref" ${install_flags[@]+"${install_flags[@]}"}
done

# dotfiles の中にあるプラグイン（conf/.config/herdr/plugins/<name>）は link する
if [[ -d "${DOTFILES_DIR}/conf/.config/herdr/plugins" ]]; then
  for dir in "${DOTFILES_DIR}"/conf/.config/herdr/plugins/*/; do
    [[ -f "${dir}herdr-plugin.toml" ]] || continue
    id="$(sed -n 's/^id *= *"\(.*\)"/\1/p' "${dir}herdr-plugin.toml" | head -1)"
    if grep -q "$id" <<<"$installed"; then
      echo "skip: $id (installed)"
      continue
    fi
    echo "link: ${dir%/}"
    herdr plugin link "${dir%/}"
  done
fi

herdr plugin list
