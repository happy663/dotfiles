#!/usr/bin/env bash
# scope-hash.sh
# 標準入力からパス列（1行1パス）を受け取り、固定長16文字のスコープハッシュを出力する。
# - 空行は無視
# - 順序非依存（sort -u で正規化）
# - 重複は除去
# - 正規化後に1件も残らなければ非0終了
set -u

# 空行を除いて sort -u
tmp=$(grep -v '^[[:space:]]*$' | sort -u)

if [[ -z "$tmp" ]]; then
    echo "scope-hash: empty input" >&2
    exit 1
fi

# macOSは shasum、Linuxは sha256sum。両方フォールバック対応。
if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$tmp" | shasum -a 256 | awk '{print $1}' | cut -c1-16
elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$tmp" | sha256sum | awk '{print $1}' | cut -c1-16
else
    echo "scope-hash: shasum or sha256sum not found" >&2
    exit 2
fi
