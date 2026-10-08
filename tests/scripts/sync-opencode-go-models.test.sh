#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OPENCODE_SYNC_LIB=1 source "${REPO_ROOT}/scripts/sync-opencode-go-models.sh"

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

fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT

cat >"$fixture" <<'EOF'
<Tabs syncKey="go-plan">
  <TabItem label="Go">

    | Model                            | Input | Output | Cached Read | Cached Write | Monthly limit |
    | -------------------------------- | ----- | ------ | ----------- | ------------ | ------------- |
    | LongCat 2.5 Preview Free         | Free  | Free   | Free        | -            | Unlimited     |
    | Claude Haiku 5.5 (≤ 100K tokens) | $0.10 | $0.50  | $0.01       | $0.125       | $15           |
    | Claude Haiku 5.5 (> 100K tokens) | $0.50 | $2.50  | $0.05       | $0.625       | $15           |

  </TabItem>
</Tabs>

## Endpoints

| Model                    | Model ID                 | Endpoint                                      | AI SDK Package        |
| ------------------------ | ------------------------ | --------------------------------------------- | --------------------- |
| LongCat 2.5 Preview Free | longcat-2.5-preview-free | `https://opencode.ai/zen/go/v1/chat/completions` | `@ai-sdk/openai`    |
| Claude Haiku 5.5         | claude-haiku-5-5         | `https://opencode.ai/zen/go/v1/messages`      | `@ai-sdk/anthropic`   |
EOF

assert_eq "3" "$(extract_price_rows "$fixture" | wc -l | tr -d ' ')" \
  "indented price rows should be extracted"

prices="$(build_price_map "$fixture")"
assert_eq "0" "$(price_get "$prices" longcat-2.5-preview-free input)" \
  "Free input price should be zero"
assert_eq "0" "$(price_get "$prices" longcat-2.5-preview-free output)" \
  "Free output price should be zero"
assert_eq "0" "$(price_get "$prices" longcat-2.5-preview-free cacheRead)" \
  "Free cached-read price should be zero"
assert_eq "0.10" "$(price_get "$prices" claude-haiku-5-5 input)" \
  "endpoint Model ID should be used for tiered price rows"
assert_eq "100000" "$(jq -r '.["claude-haiku-5-5"].tiers[0].inputTokensAbove' <<<"$prices")" \
  "tier threshold should be preserved"

echo "PASS: sync-opencode-go-models parser"
