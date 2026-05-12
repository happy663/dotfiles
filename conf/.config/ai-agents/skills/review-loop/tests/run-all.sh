#!/usr/bin/env bash
# 全テストを順次実行する。1つでも失敗したら非0で終了する。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAIL=0
for f in "$SCRIPT_DIR"/test_*.sh; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f")
    printf '=== %s ===\n' "$name"
    if bash "$f"; then
        :
    else
        FAIL=$((FAIL + 1))
    fi
done

if [[ "$FAIL" -gt 0 ]]; then
    printf '\n%d test file(s) failed\n' "$FAIL"
    exit 1
fi
printf '\nALL TESTS PASSED\n'
