#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BASE_DIR="$STATE_HOME/ai-tmux"
LOG_DIR="$BASE_DIR/logs"
JOB_DIR="$BASE_DIR/jobs"

usage() {
  cat <<'USAGE'
Usage:
  ai-tmux.sh start <name> -- <command...>
  ai-tmux.sh list
  ai-tmux.sh show <name> [-n lines]
  ai-tmux.sh attach <name>
  ai-tmux.sh stop <name>
  ai-tmux.sh close <name>

Names may contain only A-Za-z0-9_.-.
USAGE
}

die() {
  echo "ai-tmux: $*" >&2
  exit 1
}

ensure_dirs() {
  mkdir -p "$LOG_DIR" "$JOB_DIR"
}

validate_name() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "missing job name"
  [[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] || die "invalid job name: $name"
}

session_name() {
  printf 'ai-%s' "$1"
}

log_path() {
  printf '%s/%s.log' "$LOG_DIR" "$1"
}

meta_path() {
  printf '%s/%s.env' "$JOB_DIR" "$1"
}

shell_quote() {
  local out=""
  local arg
  for arg in "$@"; do
    printf -v out '%s %q' "$out" "$arg"
  done
  printf '%s' "${out# }"
}

write_meta() {
  local name="$1"
  local status="$2"
  local exit_code="${3:-}"
  local session
  local log
  local meta
  session="$(session_name "$name")"
  log="$(log_path "$name")"
  meta="$(meta_path "$name")"

  {
    printf 'name=%q\n' "$name"
    printf 'session=%q\n' "$session"
    printf 'status=%q\n' "$status"
    printf 'cwd=%q\n' "$PWD"
    printf 'log=%q\n' "$log"
    printf 'updated_at=%q\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    if [[ -n "$exit_code" ]]; then
      printf 'exit_code=%q\n' "$exit_code"
    fi
  } > "$meta"
}

read_meta_value() {
  local file="$1"
  local key="$2"
  if [[ -f "$file" ]]; then
    (
      set +u
      # shellcheck disable=SC1090
      source "$file"
      printf '%s' "${!key:-}"
    )
  fi
}

set_tmux_status() {
  local target="$1"
  local status="$2"
  tmux set-option -w -t "$target" automatic-rename off 2>/dev/null || true
  tmux set-option -w -t "$target" @agent-status "$status" 2>/dev/null || true
}

cmd_start() {
  local name="${1:-}"
  validate_name "$name"
  shift || true
  [[ "${1:-}" == "--" ]] || die "start requires -- before command"
  shift
  [[ "$#" -gt 0 ]] || die "missing command"

  ensure_dirs

  local session
  session="$(session_name "$name")"
  if tmux has-session -t "$session" 2>/dev/null; then
    die "session already exists: $session"
  fi

  local script_path
  script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  local cwd="$PWD"
  local log
  log="$(log_path "$name")"

  : > "$log"
  write_meta "$name" "running"

  tmux new-session -d -s "$session" -c "$cwd"
  set_tmux_status "$session:1" "running"
  tmux rename-window -t "$session:1" "$name" 2>/dev/null || true

  local command_line
  command_line="$(shell_quote "$script_path" "__run" "$name" "$cwd" "--" "$@")"
  tmux send-keys -t "$session:1" "$command_line" C-m

  printf 'started %s\n' "$session"
  printf 'log %s\n' "$log"
}

cmd_run() {
  local name="$1"
  local cwd="$2"
  shift 2
  [[ "${1:-}" == "--" ]] || die "__run requires -- before command"
  shift

  ensure_dirs
  cd "$cwd"

  local log
  log="$(log_path "$name")"

  write_meta "$name" "running"
  if [[ -n "${TMUX_PANE:-}" ]]; then
    set_tmux_status "$TMUX_PANE" "running"
    tmux rename-window -t "$TMUX_PANE" "$name" 2>/dev/null || true
  fi

  {
    printf '[ai-tmux] started_at=%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    printf '[ai-tmux] cwd=%s\n' "$PWD"
    printf '[ai-tmux] command=%s\n' "$(shell_quote "$@")"
  } | tee -a "$log"

  set +e
  "$@" 2>&1 | tee -a "$log"
  local cmd_status=${PIPESTATUS[0]}
  set -e

  {
    printf '[ai-tmux] finished_at=%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    printf '[ai-tmux] exit_code=%s\n' "$cmd_status"
    printf '[ai-tmux] log=%s\n' "$log"
  } | tee -a "$log"

  if [[ "$cmd_status" -eq 0 ]]; then
    write_meta "$name" "done" "$cmd_status"
    [[ -n "${TMUX_PANE:-}" ]] && set_tmux_status "$TMUX_PANE" "done"
  else
    write_meta "$name" "error" "$cmd_status"
    [[ -n "${TMUX_PANE:-}" ]] && set_tmux_status "$TMUX_PANE" "error"
  fi

  return "$cmd_status"
}

cmd_list() {
  ensure_dirs
  local file
  local found=0
  printf '%-24s %-10s %-8s %s\n' "NAME" "STATUS" "EXIT" "SESSION"
  for file in "$JOB_DIR"/*.env; do
    [[ -e "$file" ]] || continue
    found=1
    local name status exit_code session
    name="$(read_meta_value "$file" name)"
    status="$(read_meta_value "$file" status)"
    exit_code="$(read_meta_value "$file" exit_code)"
    session="$(read_meta_value "$file" session)"
    if [[ -n "$session" ]] && ! tmux has-session -t "$session" 2>/dev/null; then
      session="${session} (closed)"
    fi
    printf '%-24s %-10s %-8s %s\n' "$name" "${status:-unknown}" "${exit_code:--}" "${session:-}"
  done
  [[ "$found" -eq 1 ]] || printf 'no jobs\n'
}

cmd_show() {
  local name="${1:-}"
  validate_name "$name"
  shift || true
  local lines=120
  if [[ "${1:-}" == "-n" ]]; then
    lines="${2:-}"
    [[ "$lines" =~ ^[0-9]+$ ]] || die "invalid line count: $lines"
  fi

  local meta
  local log
  meta="$(meta_path "$name")"
  log="$(log_path "$name")"
  [[ -f "$meta" ]] || die "unknown job: $name"

  echo "== meta =="
  sed -n '1,120p' "$meta"
  echo "== log =="
  if [[ -f "$log" ]]; then
    tail -n "$lines" "$log"
  else
    echo "log not found: $log"
  fi
}

cmd_attach() {
  local name="${1:-}"
  validate_name "$name"
  local session
  session="$(session_name "$name")"
  tmux has-session -t "$session" 2>/dev/null || die "session not found: $session"
  tmux attach -t "$session"
}

cmd_stop() {
  local name="${1:-}"
  validate_name "$name"
  local session
  session="$(session_name "$name")"
  tmux has-session -t "$session" 2>/dev/null || die "session not found: $session"
  tmux send-keys -t "$session:1" C-c
  write_meta "$name" "waiting"
  set_tmux_status "$session:1" "waiting"
  printf 'sent C-c to %s\n' "$session"
}

cmd_close() {
  local name="${1:-}"
  validate_name "$name"
  local session
  session="$(session_name "$name")"
  tmux has-session -t "$session" 2>/dev/null || die "session not found: $session"
  tmux kill-session -t "$session"
  printf 'closed %s\n' "$session"
}

main() {
  local command="${1:-}"
  shift || true
  case "$command" in
    start) cmd_start "$@" ;;
    list) cmd_list "$@" ;;
    show) cmd_show "$@" ;;
    attach) cmd_attach "$@" ;;
    stop) cmd_stop "$@" ;;
    close) cmd_close "$@" ;;
    __run) cmd_run "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command: $command" ;;
  esac
}

main "$@"
