#!/usr/bin/env bash
# Hammerspoonなどの自動実行から呼ばれることを想定。
# home-managerが評価するファイルがdirtyでないことを確認してから
# make update-apply-npm を実行する。
#
# Exit codes（10/11 はGNU makeのError 2と衝突しないように2桁を採用）:
#   0   : 更新成功
#   10  : home-manager関連ファイルがdirtyでスキップ
#   11  : ネットワーク未接続でスキップ
#   その他: 実際の失敗（make/curl/git からの伝播）

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# home-manager の myHomeConfig-darwin が評価するファイル群のうち、
# 「ユーザーが手動編集する可能性があるもの」だけを監視対象にする。
# nix-darwin (default.nix) や conf/.claude/* 等は home-manager の評価対象外なので除外。
# package-lock.json はこのスクリプト自身が再生成するため除外（含めると2日目以降dirty判定でスキップし続ける）。
WATCHED_FILES=(
  "flake.nix"
  "flake.lock"
  "conf/.config/nix/home-manager/darwin.nix"
  "conf/.config/nix/home-manager/common.nix"
  "conf/.config/nix/node-pkgs/package.json"
)

DIRTY="$(git diff --name-only HEAD -- "${WATCHED_FILES[@]}")"
if [[ -n "$DIRTY" ]]; then
  echo "Skipping auto-update: home-manager related files are dirty:" >&2
  echo "$DIRTY" >&2
  exit 10
fi

if ! curl -sfI --max-time 5 https://registry.npmjs.org/ -o /dev/null; then
  echo "Skipping auto-update: cannot reach registry.npmjs.org" >&2
  exit 11
fi

echo "Running make update-apply-npm ..."
exec make update-apply-npm
