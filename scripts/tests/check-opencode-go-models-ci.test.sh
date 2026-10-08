#!/usr/bin/env bash
# CIラッパーの終了コードとJob Summaryを、同期処理のstubで検証する。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="${REPO_ROOT}/scripts/check-opencode-go-models-ci.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$TARGET" ]] || fail "CI wrapper does not exist"

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
cp "$TARGET" "$sandbox/check-opencode-go-models-ci.sh"

cat >"$sandbox/sync-opencode-go-models.sh" <<'EOF'
#!/usr/bin/env bash
[[ "$#" == 1 && "$1" == "--check" ]] || exit 99
printf 'sync stdout: status=%s\n' "$STUB_STATUS"
printf 'sync stderr: diagnostic\n' >&2
exit "$STUB_STATUS"
EOF

check_status() {
  local source_status="$1" expected_status="$2" expected_message="$3"
  local summary="$sandbox/summary-${source_status}.md"
  local output="$sandbox/output-${source_status}.log"
  local actual_status
  printf 'Existing summary\n' >"$summary"
  if STUB_STATUS="$source_status" GITHUB_STEP_SUMMARY="$summary" \
    bash "$sandbox/check-opencode-go-models-ci.sh" >"$output" 2>&1; then
    actual_status=0
  else
    actual_status=$?
  fi
  [[ "$actual_status" == "$expected_status" ]] || \
    fail "status ${source_status}: expected exit ${expected_status}, got ${actual_status}"
  grep -Fq 'Existing summary' "$summary" || fail "existing summary was overwritten"
  grep -Fq "$expected_message" "$summary" || fail "missing result for status ${source_status}"
  grep -Fq "Exit code: ${source_status}" "$summary" || fail "missing original status"
  grep -Fq "sync stdout: status=${source_status}" "$summary" || fail "missing stdout in summary"
  grep -Fq 'sync stderr: diagnostic' "$summary" || fail "missing stderr in summary"
  grep -Fq "sync stdout: status=${source_status}" "$output" || fail "missing stdout in job log"
  grep -Fq 'sync stderr: diagnostic' "$output" || fail "missing stderr in job log"
}

check_status 0 0 'No model changes detected.'
check_status 1 0 'Model updates detected; manual review and apply required.'
check_status 10 0 'Skipped: models.json has uncommitted changes.'
check_status 11 0 'Skipped: upstream sources are unreachable.'
check_status 4 4 'Check failed.'
check_status 3 3 'Check failed.'
check_status 2 2 'Check failed.'
check_status 127 127 'Check failed.'

echo 'PASS: OpenCode Go CI exit codes and Job Summary'
