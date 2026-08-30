#!/usr/bin/env bash
# 簡易アサーション関数
# - assert_eq: 厳密一致
# - assert_neq: 不一致
# - assert_contains: 部分一致 (haystack に needle が含まれる)
# - assert_true: 式が真
# - assert_pass / assert_fail: 任意ラベルで強制 pass/fail
#
# 集計用変数: PASS, FAIL
# テスト関数の末尾で `report_assertions` を呼ぶ運用も可能だが、
# シェルスクリプト全体で集計したいので各テストスクリプト末尾で exit 判定する。
set -u
: "${PASS:=0}"
: "${FAIL:=0}"

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        printf '  PASS: %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL: %s\n' "$label"
        printf '    expected: %q\n' "$expected"
        printf '    actual:   %q\n' "$actual"
        FAIL=$((FAIL + 1))
    fi
}

assert_neq() {
    local label="$1" a="$2" b="$3"
    if [[ "$a" != "$b" ]]; then
        printf '  PASS: %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL: %s (両者一致: %q)\n' "$label" "$a"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        printf '  PASS: %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL: %s\n' "$label"
        printf '    needle:   %q\n' "$needle"
        printf '    haystack: %q\n' "$haystack"
        FAIL=$((FAIL + 1))
    fi
}

assert_true() {
    local label="$1" expr="$2"
    if eval "$expr"; then
        printf '  PASS: %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL: %s (条件: %s)\n' "$label" "$expr"
        FAIL=$((FAIL + 1))
    fi
}

assert_pass() {
    printf '  PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

assert_fail() {
    printf '  FAIL: %s\n' "$1"
    FAIL=$((FAIL + 1))
}

# テストスクリプトの末尾で呼んで終了コードを決める
report_assertions() {
    printf '%d passed, %d failed\n' "$PASS" "$FAIL"
    [[ "$FAIL" -eq 0 ]]
}

# 異常終了時にもレポート出す
trap 'report_assertions || exit 1' EXIT
