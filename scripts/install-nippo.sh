#!/bin/zsh
# nippo (Claude Code / Codex 日報スキル) のセットアップ
# - ghq で nippo リポジトリを取得
# - Rust バイナリをインストール
# 別途 scripts/link.sh が skill の symlink を張る
set -e

REPO="github.com/nwiizo/nippo"

if ! command -v ghq >/dev/null 2>&1; then
    echo "Error: ghq が必要です。"
    exit 1
fi
if ! command -v cargo >/dev/null 2>&1; then
    echo "Error: cargo が必要です。"
    exit 1
fi

if ! ghq list 2>/dev/null | grep -q "^${REPO}$"; then
    echo "Cloning ${REPO} ..."
    ghq get "$REPO"
else
    echo "Found ${REPO} in ghq."
fi

NIPPO_REPO="$(ghq root)/${REPO}"
echo "Installing nippo binary from ${NIPPO_REPO} ..."
cargo install --path "${NIPPO_REPO}/crates/collector"

echo ""
echo "Done. nippo: $(command -v nippo)"
echo "Run 'make link' to create the skill symlink."
