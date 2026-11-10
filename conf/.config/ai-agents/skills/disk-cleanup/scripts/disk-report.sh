#!/usr/bin/env bash
# Nix Store 以外でディスクを圧迫している場所を計測して一覧にする。
# 読み取り専用で、何も削除しない。削除の判断は ../SKILL.md を参照。
#
# 環境変数:
#   DISK_REPORT_HOME         計測するホーム（既定: $HOME）
#   DISK_REPORT_APPS         計測するアプリディレクトリ（既定: /Applications）
#   DISK_REPORT_TOP          上位何件を出すか（既定: 20）
#   DISK_REPORT_SKIP_SYSTEM  1 なら df / diskutil / docker を呼ばない（テスト用）
#   DISK_REPORT_LIB          1 なら関数定義だけ読み込んで終了する（テスト用）

set -euo pipefail

# KB 単位の数値を du -h 風の表記にする（10 未満は小数1桁）
format_kb() {
  awk -v kb="$1" 'BEGIN {
    if (kb < 1024) { printf "%dK\n", kb; exit }
    if (kb < 1048576) { v = kb / 1024; u = "M" } else { v = kb / 1048576; u = "G" }
    if (v < 10) printf "%.1f%s\n", v, u; else printf "%d%s\n", v + 0.5, u
  }'
}

# 標準入力のパス（1行1件）を計測し「サイズ<TAB>パス」を大きい順に出す。
# 存在しないパスは出さない。
size_table() {
  local path kb
  while IFS= read -r path; do
    [[ -n "$path" && -e "$path" ]] || continue
    kb="$(du -skx "$path" 2>/dev/null | awk 'NR == 1 { print $1 }')" || true
    [[ -n "$kb" ]] || continue
    printf '%s\t%s\n' "$kb" "$path"
  done | sort -t $'\t' -k1,1nr | while IFS=$'\t' read -r kb path; do
    printf '%s\t%s\n' "$(format_kb "$kb")" "$path"
  done
}

# ディレクトリ直下の子（ドットファイル含む）を大きい順に N 件
top_children() {
  local dir="$1" n="$2"
  [[ -d "$dir" ]] || return 0
  find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | size_table | awk -v n="$n" 'NR <= n'
}

# lima の VM ディスクを「実使用量<TAB>見かけのサイズ<TAB>パス」で出す。
# VM ディスクはスパースファイルなので ls -l の値（見かけ）は実使用量と大きく違う。
vm_disks() {
  local lima_home="$1" f actual bytes
  [[ -d "$lima_home" ]] || return 0
  find "$lima_home" -maxdepth 3 -type f \
    \( -name diffdisk -o -name datadisk -o -name basedisk \) 2>/dev/null |
    sort | while IFS= read -r f; do
      actual="$(du -sk "$f" | awk '{ print $1 }')"
      # stat の書式は GNU と BSD で違うため、両方で同じ列を返す ls -ln を使う
      # shellcheck disable=SC2012
      bytes="$(ls -ln "$f" | awk '{ print $5 }')"
      printf '%s\t%s\t%s\n' "$(format_kb "$actual")" "$(format_kb "$((bytes / 1024))")" "$f"
    done
}

# COLIMA_HOME/_lima が使われていない（LIMA_HOME が別の場所を指す）なら、そのパスを出す。
# LIMA_HOME 未設定なら colima は COLIMA_HOME/_lima を使うので候補にしない。
stale_lima_dir() {
  local colima_home="$1" lima_home="$2" candidate resolved_candidate resolved_lima
  candidate="${colima_home}/_lima"
  [[ -d "$candidate" ]] || return 0
  [[ -n "$lima_home" ]] || return 0
  resolved_candidate="$(cd "$candidate" && pwd -P)"
  resolved_lima="$(cd "$lima_home" 2>/dev/null && pwd -P)" || true
  [[ "$resolved_candidate" != "$resolved_lima" ]] || return 0
  echo "$candidate"
}

# 過去に大きくなったことがある既知の場所
known_hotspots() {
  local home="$1" apps="$2" colima_home="$3" lima_home="$4"
  cat <<EOF
${lima_home}
${colima_home}
${home}/Library/Caches/colima
${home}/.npm
${home}/.cache/uv
${home}/Library/Caches/Homebrew
${home}/Library/Caches/Coursier
${home}/Library/Caches/ms-playwright
${home}/Library/Caches/JetBrains
${home}/.local/share/mise
${home}/.local/share/nvim
${home}/.gradle
${home}/.rustup
${home}/.ivy2
${home}/.cargo
${home}/go
${home}/Library/Application Support/Claude/vm_bundles
${home}/Library/Developer
${home}/Downloads
${home}/screencapture
${home}/.Trash
EOF
  local editor
  for editor in "${apps}"/Unity/Hub/Editor/*; do
    [[ -e "$editor" ]] && echo "$editor"
  done
  return 0
}

print_table_or_none() {
  local body="$1"
  if [[ -n "$body" ]]; then
    printf '%s\n' "$body"
  else
    echo "(none)"
  fi
}

run_with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    "$@"
  fi
}

report_volumes() {
  echo "## Volumes"
  df -h / || true
  if command -v diskutil >/dev/null 2>&1; then
    echo
    echo "APFS volumes (Capacity Consumed):"
    diskutil apfs list 2>/dev/null | awk '
      /Name:/ { sub(/.*Name:[ ]+/, ""); name = $0 }
      /Capacity Consumed:/ { sub(/.*\(/, ""); sub(/\).*/, ""); printf "  %-30s %s\n", name, $0 }
    ' || true
  fi
  if command -v tmutil >/dev/null 2>&1; then
    echo
    echo "Local snapshots:"
    tmutil listlocalsnapshots / 2>/dev/null | sed -n '2,$p' | sed 's/^/  /' || true
  fi
  echo
}

report_docker() {
  echo "## Docker (inside VM)"
  if command -v docker >/dev/null 2>&1; then
    run_with_timeout 60 docker system df 2>&1 || echo "(docker not responding)"
  else
    echo "(docker not installed)"
  fi
  echo
}

main() {
  local home="${DISK_REPORT_HOME:-$HOME}"
  local apps="${DISK_REPORT_APPS:-/Applications}"
  local top="${DISK_REPORT_TOP:-20}"
  local skip_system="${DISK_REPORT_SKIP_SYSTEM:-0}"
  local colima_home="${COLIMA_HOME:-${home}/.colima}"
  local lima_home="${LIMA_HOME:-${colima_home}/_lima}"

  echo "# Disk report (read-only, Nix Store excluded)"
  echo "COLIMA_HOME=${colima_home}"
  echo "LIMA_HOME=${lima_home}"
  echo

  if [[ "$skip_system" != 1 ]]; then
    report_volumes
  fi

  echo "## Home top ${top} (${home})"
  echo "measuring ${home} ..." >&2
  print_table_or_none "$(top_children "$home" "$top")"
  echo

  echo "## Known hotspots"
  print_table_or_none "$(known_hotspots "$home" "$apps" "$colima_home" "$lima_home" | size_table)"
  echo

  echo "## VM disks (actual / apparent / path)"
  print_table_or_none "$(vm_disks "$lima_home")"
  echo

  echo "## Stale lima (COLIMA_HOME/_lima not used by LIMA_HOME)"
  print_table_or_none "$(stale_lima_dir "$colima_home" "${LIMA_HOME:-}" | size_table)"
  echo

  if [[ "$skip_system" != 1 ]]; then
    report_docker
  fi

  echo "## Applications top ${top} (${apps})"
  print_table_or_none "$(top_children "$apps" "$top")"
}

if [[ "${DISK_REPORT_LIB:-0}" != 1 ]]; then
  main "$@"
fi
