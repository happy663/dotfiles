#!/usr/bin/env bash
set -u

force=0
for arg in "$@"; do
  case "$arg" in
    --force)
      force=1
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node_pkgs_dir="$repo_root/conf/.config/nix/node-pkgs"
lockfile="$node_pkgs_dir/package-lock.json"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
state_dir="$state_home/dotfiles"
last_success_file="$state_dir/update-node-tools.last-success"
lock_dir="$state_dir/update-node-tools.lock"
log_file="$state_dir/update-node-tools.log"
today="$(date '+%Y-%m-%d')"

mkdir -p "$state_dir"

emit() {
  printf '%s\n' "$*" >&3
}

mark_success() {
  printf '%s\n' "$today" > "$last_success_file"
}

rotate_logs() {
  rm -f "$log_file.5"
  for i in 4 3 2 1; do
    if [ -f "$log_file.$i" ]; then
      mv "$log_file.$i" "$log_file.$((i + 1))"
    fi
  done
  if [ -f "$log_file" ]; then
    mv "$log_file" "$log_file.1"
  fi
  : > "$log_file"
}

cleanup_lock() {
  if [ -d "$lock_dir" ] && [ "$(cat "$lock_dir/pid" 2>/dev/null || true)" = "$$" ]; then
    rm -f "$lock_dir/pid" "$lock_dir/started_at"
    rmdir "$lock_dir" 2>/dev/null || true
  fi
}

fail_result() {
  stage="$1"
  lockfile_state="$2"
  emit "RESULT=failed"
  emit "FAILED_STAGE=$stage"
  emit "LOCKFILE_STATE=$lockfile_state"
  emit "LOG_FILE=$log_file"
  exit 1
}

if [ "$force" -eq 0 ] && [ -f "$last_success_file" ] && [ "$(cat "$last_success_file")" = "$today" ]; then
  exec 3>&1
  emit "RESULT=skipped"
  emit "LOG_FILE=$log_file"
  exit 0
fi

exec 3>&1
rotate_logs
exec >> "$log_file" 2>&1

echo "started_at=$(date '+%Y-%m-%d %H:%M:%S')"
echo "repo_root=$repo_root"
echo "force=$force"

if ! mkdir "$lock_dir" 2>/dev/null; then
  existing_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
  if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "another update-node-tools process is running: pid=$existing_pid"
    emit "RESULT=locked"
    emit "LOG_FILE=$log_file"
    exit 0
  fi

  echo "removing stale lock: $lock_dir"
  rm -f "$lock_dir/pid" "$lock_dir/started_at"
  rmdir "$lock_dir" 2>/dev/null || true
  if ! mkdir "$lock_dir" 2>/dev/null; then
    echo "failed to acquire lock after stale cleanup"
    fail_result "unknown" "unchanged"
  fi
fi

printf '%s\n' "$$" > "$lock_dir/pid"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$lock_dir/started_at"
trap cleanup_lock EXIT

case "$(uname -s)" in
  Darwin)
    home_config="myHomeConfig-darwin"
    ;;
  Linux)
    home_config="myHomeConfig-linux"
    ;;
  *)
    echo "unsupported system: $(uname -s)"
    fail_result "unknown" "unchanged"
    ;;
esac

backup="$(mktemp)"
cleanup_backup() {
  rm -f "$backup"
}
trap 'cleanup_backup; cleanup_lock' EXIT

cp -p "$lockfile" "$backup"

echo "updating npm lockfile"
(
  cd "$node_pkgs_dir" || exit 1
  rm package-lock.json
  npm install --package-lock-only
)
npm_status=$?
if [ "$npm_status" -ne 0 ]; then
  echo "npm lockfile update failed: status=$npm_status"
  cp -p "$backup" "$lockfile"
  fail_result "npm" "restored"
fi

if cmp -s "$backup" "$lockfile"; then
  echo "package-lock.json is unchanged"
  cp -p "$backup" "$lockfile"
  mark_success
  emit "RESULT=noop"
  emit "LOG_FILE=$log_file"
  exit 0
fi

echo "package-lock.json changed"
echo "building nodeTools"
(
  cd "$repo_root" || exit 1
  nix build --no-link .#nodeTools
)
build_status=$?
if [ "$build_status" -ne 0 ]; then
  echo "nix build failed: status=$build_status"
  fail_result "build" "kept"
fi

echo "switching home-manager: $home_config"
(
  cd "$repo_root" || exit 1
  nix run nixpkgs#home-manager -- switch --flake ".#$home_config"
)
switch_status=$?
if [ "$switch_status" -ne 0 ]; then
  echo "home-manager switch failed: status=$switch_status"
  fail_result "switch" "kept"
fi

mark_success
emit "RESULT=updated"
emit "LOG_FILE=$log_file"
