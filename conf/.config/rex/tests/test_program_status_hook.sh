#!/usr/bin/env bash
# conf/.config/rex/hooks/program-status.sh のテスト。
# Claude Code の hook から呼ばれ、状態を OSC 7501 として Claude Code の端末へ書き込む。
# 書き込み先は REX_PROGRAM_STATUS_TTY でファイルに差し替えて確かめる。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
HOOK="${REPO_ROOT}/conf/.config/rex/hooks/program-status.sh"

ESC=$'\033'
OSC="${ESC}]7501;"
ST="${ESC}\\"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

b64() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
project="${sandbox}/myproj"
mkdir -p "$project"
out="${sandbox}/tty"
TITLE="$(b64 myproj)"

# hook を実行し、書き込まれた内容を返す。
# 引数: <hook の引数> <stdin に渡す JSON> [env の追加 (KEY=VALUE ...)]
run_hook() {
  local arg="$1" input="$2"
  shift 2
  : >"$out"
  (
    cd "$project"
    printf '%s' "$input" | env -u CLAUDE_TASK_RENAMER -u CODEX_TASK_RENAMER -u PI_TASK_RENAMER \
      REX_SESSION=session:test REX_PROGRAM_STATUS_TTY="$out" "$@" bash "$HOOK" "$arg"
  ) || fail "hook exited non-zero for '$arg'"
  cat "$out"
}

assert_written() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" != "$expected" ]]; then
    fail "${name}
expected: $(printf '%q' "$expected")
  actual: $(printf '%q' "$actual")"
  fi
  echo "ok: ${name}"
}

assert_written "working" \
  "${OSC}state=working:app=claude-code:title=${TITLE}${ST}" \
  "$(run_hook working '{}')"

assert_written "done" \
  "${OSC}state=done:app=claude-code:title=${TITLE}${ST}" \
  "$(run_hook done '{}')"

assert_written "error" \
  "${OSC}state=error:app=claude-code:title=${TITLE}${ST}" \
  "$(run_hook error '{}')"

assert_written "clear" \
  "${OSC}state=clear${ST}" \
  "$(run_hook clear '{}')"

assert_written "notification: permission_prompt は blocked / permission" \
  "${OSC}state=blocked:kind=permission:app=claude-code:title=${TITLE}:msg=$(b64 'Claude needs your permission to use Bash')${ST}" \
  "$(run_hook notification '{"notification_type":"permission_prompt","message":"Claude needs your permission to use Bash"}')"

assert_written "notification: elicitation_dialog は blocked / question" \
  "${OSC}state=blocked:kind=question:app=claude-code:title=${TITLE}:msg=$(b64 'Pick one')${ST}" \
  "$(run_hook notification '{"notification_type":"elicitation_dialog","message":"Pick one"}')"

assert_written "notification: 種類が不明なら kind なしの blocked" \
  "${OSC}state=blocked:app=claude-code:title=${TITLE}:msg=$(b64 'Something')${ST}" \
  "$(run_hook notification '{"message":"Something"}')"

assert_written "notification: idle_prompt は無視する（応答完了の done を上書きしない）" \
  "" \
  "$(run_hook notification '{"notification_type":"idle_prompt","message":"Claude is waiting for your input"}')"

assert_written "notification: メッセージ内の制御文字は空白に置き換える" \
  "${OSC}state=blocked:kind=permission:app=claude-code:title=${TITLE}:msg=$(b64 'line1 line2')${ST}" \
  "$(run_hook notification "$(printf '{"notification_type":"permission_prompt","message":"line1\\nline2"}')")"

assert_written "Rex の外（REX_SESSION なし）では何も書かない" \
  "" \
  "$(run_hook working '{}' REX_SESSION=)"

assert_written "タイトル生成用の入れ子の claude では何も書かない" \
  "" \
  "$(run_hook working '{}' CLAUDE_TASK_RENAMER=1)"

assert_written "未知の引数では何も書かない" \
  "" \
  "$(run_hook bogus '{}')"

echo "ALL OK"
