#!/usr/bin/env bash
# scope-hash.sh のユニットテスト
# 仕様:
#   - 標準入力にパス列（1行1パス）を受け取り、固定長16文字のハッシュを返す
#   - 順序非依存（同じパス集合なら順序が違っても同じハッシュ）
#   - 重複は除去される
#   - 空入力では非0終了
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$SCRIPT_DIR/scripts/scope-hash.sh"

. "$SCRIPT_DIR/tests/_assert.sh"

test_scope_hash() {
    local h1 h2 h3
    h1=$(printf 'a.ts\nb.ts\nc.ts\n' | "$TARGET")
    h2=$(printf 'c.ts\nb.ts\na.ts\n' | "$TARGET")
    assert_eq "順序非依存" "$h1" "$h2"

    h3=$(printf 'a.ts\nb.ts\nd.ts\n' | "$TARGET")
    assert_neq "異なる集合は異なるハッシュ" "$h1" "$h3"

    assert_eq "ハッシュ長16文字" 16 "${#h1}"

    # 重複除去
    local h4
    h4=$(printf 'a.ts\nb.ts\na.ts\nc.ts\n' | "$TARGET")
    assert_eq "重複除去" "$h1" "$h4"

    # 空入力 → 非0
    if printf '' | "$TARGET" >/dev/null 2>&1; then
        assert_fail "空入力でエラー終了すべき"
    else
        assert_pass "空入力でエラー終了"
    fi
}

test_scope_hash
