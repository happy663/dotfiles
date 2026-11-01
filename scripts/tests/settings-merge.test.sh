#!/usr/bin/env bash
# claude-settings.sh / pi-settings.sh の pull / push 挙動を固定するテスト。
# サンドボックスに scripts/ と conf/ をコピーし、HOME を差し替えて実行する。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
home="${sandbox}/home"

# サンドボックスを作り直す。scripts/ と conf/ をコピーし、git リポジトリとして初期化する
# (pull の最後に git diff を呼ぶため、stderr を汚さないようにする)。
reset_sandbox() {
  rm -rf "$sandbox"
  mkdir -p "$sandbox/scripts" "$sandbox/conf/.claude/presets" "$sandbox/conf/.pi/agent" "$home"

  cp "$REPO_ROOT"/scripts/claude-settings.sh "$sandbox/scripts/"
  cp "$REPO_ROOT"/scripts/pi-settings.sh "$sandbox/scripts/"
  if [[ -f "$REPO_ROOT/scripts/lib/settings-merge.sh" ]]; then
    mkdir -p "$sandbox/scripts/lib"
    cp "$REPO_ROOT"/scripts/lib/settings-merge.sh "$sandbox/scripts/lib/"
  fi

  cp "$REPO_ROOT"/conf/.claude/settings.base.json "$sandbox/conf/.claude/"
  cp "$REPO_ROOT"/conf/.claude/settings.local.example.json "$sandbox/conf/.claude/"
  cp "$REPO_ROOT"/conf/.claude/presets/managed-paths.json "$sandbox/conf/.claude/presets/"
  cp "$REPO_ROOT"/conf/.pi/agent/settings.base.json "$sandbox/conf/.pi/agent/"
  cp "$REPO_ROOT"/conf/.pi/agent/settings.local.example.json "$sandbox/conf/.pi/agent/"
  cp "$REPO_ROOT"/conf/.pi/agent/managed-paths.json "$sandbox/conf/.pi/agent/"

  git -C "$sandbox" init -q
  git -C "$sandbox" add -A
  git -C "$sandbox" -c user.email=test@example.com -c user.name=test commit -qm init
}

run_tool() {
  local script="$1"
  shift
  HOME="$home" bash "$sandbox/scripts/${script}" "$@" >/dev/null 2>&1
}

# 1 ツール分のシナリオを検証する
check_tool() {
  local script="$1" label="$2"
  local active_rel="$3" base_rel="$4" local_rel="$5" example_rel="$6" managed_rel="$7"

  local active="${home}/${active_rel}"
  local base="${sandbox}/${base_rel}"
  local local_file="${home}/${local_rel}"
  local example="${sandbox}/${example_rel}"
  local managed="${sandbox}/${managed_rel}"

  # --- push: local が無ければ example から初期化し、base とマージする ---
  reset_sandbox
  run_tool "$script" push
  [[ -f "$local_file" ]] || fail "${label}: push should create local.json"
  [[ -f "$active" ]] || fail "${label}: push should create active settings.json"
  assert_eq "$(jq -S -s '.[0] * .[1]' "$base" "$example")" "$(jq -S . "$active")" \
    "${label}: push should merge base and example"

  # --- push は冪等 ---
  local before after
  before="$(jq -S . "$active")"
  run_tool "$script" push
  after="$(jq -S . "$active")"
  assert_eq "$before" "$after" "${label}: push should be idempotent"

  # --- push は active の symlink を実ファイルに置き換える ---
  reset_sandbox
  mkdir -p "$(dirname "$active")"
  printf '{}' >"${sandbox}/dummy.json"
  ln -s "${sandbox}/dummy.json" "$active"
  run_tool "$script" push
  [[ -L "$active" ]] && fail "${label}: push should replace symlinked active"
  [[ -f "$active" ]] || fail "${label}: push should write active as regular file"

  # --- pull: managed path を local へ分離し、base から取り除く ---
  reset_sandbox
  run_tool "$script" push
  local first_path
  first_path="$(jq -c '.[0]' "$managed")"
  jq --argjson p "$first_path" 'setpath($p; "__probe__")' "$active" >"${sandbox}/probe.json"
  mv "${sandbox}/probe.json" "$active"

  run_tool "$script" pull
  assert_eq "null" "$(jq --argjson p "$first_path" 'getpath($p)' "$base")" \
    "${label}: pull should remove managed path from base"
  assert_eq '"__probe__"' "$(jq --argjson p "$first_path" -c 'getpath($p)' "$local_file")" \
    "${label}: pull should move managed path into local"
  assert_eq "$(jq -S . "$active")" "$(jq -S -s '.[0] * .[1]' "$base" "$local_file")" \
    "${label}: base * local should reproduce active after pull"

  # --- pull -> push の往復で内容が変わらない ---
  local expected
  expected="$(jq -S . "$active")"
  run_tool "$script" push
  assert_eq "$expected" "$(jq -S . "$active")" \
    "${label}: push after pull should be a no-op"

  # --- pull: active が無ければ失敗する ---
  reset_sandbox
  mkdir -p "$(dirname "$active")"
  if run_tool "$script" pull; then
    fail "${label}: pull should fail when active settings.json is missing"
  fi

  # --- pull: active が symlink なら失敗する ---
  reset_sandbox
  mkdir -p "$(dirname "$active")"
  printf '{}' >"${sandbox}/dummy.json"
  ln -s "${sandbox}/dummy.json" "$active"
  if run_tool "$script" pull; then
    fail "${label}: pull should fail when active settings.json is a symlink"
  fi

  # --- managed-paths.json が無ければ失敗する ---
  reset_sandbox
  run_tool "$script" push
  mv "$managed" "${managed}.bak"
  if run_tool "$script" pull; then
    fail "${label}: pull should fail when managed-paths.json is missing"
  fi
  mv "${managed}.bak" "$managed"
}

check_tool claude-settings.sh claude \
  ".claude/settings.json" \
  "conf/.claude/settings.base.json" \
  ".claude/settings.local.json" \
  "conf/.claude/settings.local.example.json" \
  "conf/.claude/presets/managed-paths.json"

check_tool pi-settings.sh pi \
  ".pi/agent/settings.json" \
  "conf/.pi/agent/settings.base.json" \
  ".pi/agent/settings.local.json" \
  "conf/.pi/agent/settings.local.example.json" \
  "conf/.pi/agent/managed-paths.json"

echo "PASS: settings merge (claude/pi)"
