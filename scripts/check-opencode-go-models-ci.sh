#!/usr/bin/env bash
# --checkの終了コードをCI用に分類し、診断内容をGitHub Job Summaryへ追記する。
# 差分あり(1)・スキップ(10/11)は成功、実エラーは元の終了コードで失敗する。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY must be set}"

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

if bash "${SCRIPT_DIR}/sync-opencode-go-models.sh" --check >"$log" 2>&1; then
  status=0
else
  status=$?
fi

cat "$log"

result=0
case "$status" in
  0) message='No model changes detected.' ;;
  1) message='Model updates detected; manual review and apply required.' ;;
  10) message='Skipped: models.json has uncommitted changes.' ;;
  11) message='Skipped: upstream sources are unreachable.' ;;
  *)
    message='Check failed.'
    result="$status"
    ;;
esac

{
  printf '## OpenCode Go model check\n\n%s\n\n' "$message"
  printf 'Exit code: %s\n\n' "$status"
  if [[ "$status" == 1 ]]; then
    # shellcheck disable=SC2016 # Markdownのバッククォートはリテラル。
    printf 'Review the changes below, then run `make sync-opencode-go-models-apply` locally.\n\n'
  fi
  printf '````text\n'
  cat "$log"
  printf '\n````\n'
} >>"$GITHUB_STEP_SUMMARY"

exit "$result"
