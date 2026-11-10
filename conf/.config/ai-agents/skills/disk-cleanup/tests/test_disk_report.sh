#!/usr/bin/env bash

set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/disk-report.sh"
DISK_REPORT_LIB=1 source "$SCRIPT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1" actual="$2" message="$3"
  if [[ "$actual" != "$expected" ]]; then
    fail "${message}: expected '${expected}', got '${actual}'"
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" message="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "${message}: '${needle}' not found in:
${haystack}"
  fi
}

assert_not_contains() {
  local needle="$1" haystack="$2" message="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    fail "${message}: '${needle}' unexpectedly found in:
${haystack}"
  fi
}

# 指定 KB の実データを持つファイルを作る
make_file_kb() {
  local path="$1" kb="$2"
  mkdir -p "$(dirname "$path")"
  dd if=/dev/zero of="$path" bs=1024 count="$kb" 2>/dev/null
}

# 見かけのサイズだけ大きいスパースファイルを作る
make_sparse_mb() {
  local path="$1" mb="$2"
  mkdir -p "$(dirname "$path")"
  dd if=/dev/zero of="$path" bs=1 count=0 seek="$((mb * 1024 * 1024))" 2>/dev/null
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- format_kb ---
assert_eq "512K" "$(format_kb 512)" "KB は K 表記"
assert_eq "2.0M" "$(format_kb 2048)" "MB は小数1桁の M 表記"
assert_eq "1.5G" "$(format_kb 1572864)" "GB は小数1桁の G 表記"
assert_eq "0K" "$(format_kb 0)" "0 は 0K"

# --- size_table: 大きい順、存在しないパスは除外、パスに空白を含んでもよい ---
make_file_kb "$tmp/sizes/big/f" 3072
make_file_kb "$tmp/sizes/with space/f" 2048
make_file_kb "$tmp/sizes/small/f" 1024

table="$(printf '%s\n' \
  "$tmp/sizes/small" \
  "$tmp/sizes/missing" \
  "$tmp/sizes/big" \
  "$tmp/sizes/with space" | size_table)"

assert_eq "3" "$(wc -l <<<"$table" | tr -d ' ')" "存在するパスだけが行になる"
assert_eq "$tmp/sizes/big" "$(sed -n 1p <<<"$table" | cut -f2)" "1行目は最大のパス"
assert_eq "$tmp/sizes/with space" "$(sed -n 2p <<<"$table" | cut -f2)" "空白を含むパスも扱える"
assert_eq "$tmp/sizes/small" "$(sed -n 3p <<<"$table" | cut -f2)" "最後は最小のパス"
assert_not_contains "missing" "$table" "存在しないパスは出さない"
if ! grep -Eq $'^[0-9.]+[KMG]\t' <<<"$table"; then
  fail "行は「サイズ<TAB>パス」形式であるべき: $table"
fi

# --- top_children: ドットファイルを含む直下の子を大きい順に N 件 ---
make_file_kb "$tmp/home/.hidden-cache/f" 4096
make_file_kb "$tmp/home/Library/f" 2048
make_file_kb "$tmp/home/src/f" 1024
make_file_kb "$tmp/home/tiny/f" 4

top="$(top_children "$tmp/home" 2)"
assert_eq "2" "$(wc -l <<<"$top" | tr -d ' ')" "件数を N に制限する"
assert_eq "$tmp/home/.hidden-cache" "$(sed -n 1p <<<"$top" | cut -f2)" "ドットディレクトリも対象"
assert_eq "$tmp/home/Library" "$(sed -n 2p <<<"$top" | cut -f2)" "2番目に大きい子"

# --- vm_disks: 見かけのサイズと実使用量を両方出す ---
make_sparse_mb "$tmp/lima/colima/diffdisk" 100
make_file_kb "$tmp/lima/colima/basedisk" 1024
make_file_kb "$tmp/lima/colima/cidata.iso" 16

vm="$(vm_disks "$tmp/lima")"
diff_line="$(grep 'colima/diffdisk' <<<"$vm")"
assert_contains $'\t100M\t' "$diff_line" "diffdisk の見かけのサイズは 100M"
if ! grep -Eq $'^[0-9.]+K\t' <<<"$diff_line"; then
  fail "スパースな diffdisk の実使用量は K 単位のはず: $diff_line"
fi
assert_contains "colima/basedisk" "$vm" "basedisk も対象"
assert_not_contains "cidata.iso" "$vm" "ディスク以外のファイルは対象外"
assert_eq "" "$(vm_disks "$tmp/no-such-lima")" "LIMA_HOME がなければ何も出さない"

# --- stale_lima_dir: COLIMA_HOME/_lima が LIMA_HOME と別なら古い候補 ---
mkdir -p "$tmp/colima-home/_lima/colima"
assert_eq "$tmp/colima-home/_lima" \
  "$(stale_lima_dir "$tmp/colima-home" "$tmp/lima")" \
  "LIMA_HOME が別の場所なら _lima は古い候補"
assert_eq "" \
  "$(stale_lima_dir "$tmp/colima-home" "$tmp/colima-home/_lima")" \
  "LIMA_HOME が _lima 自身なら候補にしない"
assert_eq "" \
  "$(stale_lima_dir "$tmp/colima-home" "")" \
  "LIMA_HOME 未設定なら _lima は使用中なので候補にしない"
assert_eq "" \
  "$(stale_lima_dir "$tmp/no-colima-home" "$tmp/lima")" \
  "_lima がなければ何も出さない"

# --- main: システムコマンドを使わずに全セクションが出る ---
mkdir -p "$tmp/apps/Big.app"
make_file_kb "$tmp/apps/Big.app/bin" 1024
report="$(
  DISK_REPORT_HOME="$tmp/home" \
    DISK_REPORT_APPS="$tmp/apps" \
    DISK_REPORT_SKIP_SYSTEM=1 \
    COLIMA_HOME="$tmp/colima-home" \
    LIMA_HOME="$tmp/lima" \
    bash "$SCRIPT"
)"
assert_contains "## Home top" "$report" "ホーム上位のセクション"
assert_contains "## Known hotspots" "$report" "既知の大容量箇所のセクション"
assert_contains "## VM disks" "$report" "VM ディスクのセクション"
assert_contains "## Stale lima" "$report" "古い lima のセクション"
assert_contains "$tmp/colima-home/_lima" "$report" "古い lima が報告される"
assert_contains "## Applications top" "$report" "アプリのセクション"
assert_contains "$tmp/apps/Big.app" "$report" "アプリが報告される"
assert_not_contains "## Volumes" "$report" "SKIP_SYSTEM ならボリューム情報は出さない"
assert_not_contains "## Docker" "$report" "SKIP_SYSTEM なら Docker は出さない"

echo "PASS: disk-report"
