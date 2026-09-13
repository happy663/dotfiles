#!/usr/bin/env bash
# OpenCode Go の公式ドキュメント (go.mdx) と models.dev から価格・モデル一覧を取得し、
# conf/.pi/agent/models.json を同期するスクリプト。
#
# 情報源:
#   - 価格 / API タイプ: https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/web/src/content/docs/go.mdx
#   - メタデータ (contextWindow / maxTokens / reasoning / input): https://models.dev/api.json の opencode-go セクション
#
# 同期内容:
#   - cost (input/output/cacheRead/cacheWrite) を価格テーブルから更新
#   - api タイプを Endpoints テーブルから更新 (responses/chat.completions/messages)
#   - contextWindow / maxTokens / reasoning / input を models.dev のメタデータで更新
#     (models.dev に存在しないモデルのみ既存値 / 推測値を維持)
#   - 段階価格 (GPT 5.6 Luna >272K, Qwen3.7/3.6 Plus >256K) は cost.tiers で表現
#   - 新モデルは推測値 (固定マップ or デフォルト) で追加し、レポートで要確認と表示
#
# Usage:
#   sync-opencode-go-models.sh [--check|--apply]
#
# Options:
#   --check   差分検出のみ (デフォルト)。差分があれば exit 1
#   --apply   models.json を書き込む
#
# DeepSeek の価格は Peak 価格のみで管理する (Off-Peak は扱わない)
#
# Exit codes (hammerspoon の auto-update パターンに合わせる):
#   0  : 差分なし / 適用成功
#   1  : --check で差分あり
#   10 : 対象ファイルが dirty (手動編集の上書き防止) でスキップ
#   11 : ネットワーク未接続でスキップ
#   その他: パース失敗等の実エラー
#
# OPENCODE_SYNC_LIB=1 で source すると関数定義のみを読み込む (テスト用)。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODELS_PATH="conf/.pi/agent/models.json"
GO_MDX_URL="https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/web/src/content/docs/go.mdx"
MD_API_URL="https://models.dev/api.json"

# ---------------------------------------------------------------------------
# ユーティリティ
# ---------------------------------------------------------------------------

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

write_atomic() {
  local target="$1" content="$2"
  local tmp
  tmp="$(mktemp "${target}.XXXXXX")"
  printf '%s\n' "$content" >"$tmp"
  mv "$tmp" "$target"
}

# ---------------------------------------------------------------------------
# パース: モデル名 / 価格セル / 注記
# ---------------------------------------------------------------------------

# モデル表示名 → モデルID への変換 ("MiMo V2.5" → "mimo-v2.5")。
# 括弧注記は常に除去する ("GPT 5.6 Luna (≤ 272K tokens)" → "gpt-5.6-luna")
normalize_model_name() {
  local name="$1"
  name="$(strip_note "$name")"
  printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# 注記の抽出 ("GPT 5.6 Luna (≤ 272K tokens)" → "≤ 272K tokens")
extract_note() {
  sed -n 's/.*(\(.*\))$/\1/p' <<<"$1"
}

# 注記の除去 ("GPT 5.6 Luna (≤ 272K tokens)" → "GPT 5.6 Luna")
strip_note() {
  sed 's/ *([^)]*)$//' <<<"$1"
}

# 価格セル → 数値文字列 ("$2.00" → "2.00", "-" → "0")
parse_price_cell() {
  local cell="$1"
  case "$cell" in
    "" | "-") printf '0' ;;
    \$*) printf '%s' "${cell#\$}" ;;
    *) printf '%s' "$cell" ;;
  esac
}

# 注記 → tier のトークン上限 ("≤ 272K tokens" → 272000)
parse_tier_tokens() {
  local note="$1"
  local num
  # "272K" のような連続数字+K を抽出 ("≤ 272K tokens" の "272")
  num="$(grep -o '[0-9][0-9]*K' <<<"$note" | head -1)"
  if [[ -n "$num" ]]; then
    printf '%s' "$(( ${num%%K} * 1000 ))"
  fi
}

# 注記の分類:
#   normal: 単価のみのモデル
#   base  : 段階価格のベース側 ("≤ 272K tokens")
#   tier  : 段階価格の超過側 ("> 272K tokens")
#   time  : 時間帯別価格 ("Off-Peak" / "Peak")
classify_note() {
  local note="$1"
  local le=$'\u2264' # ≤
  case "$note" in
    "") printf 'normal' ;;
    "${le}"* | "<="*) printf 'base' ;;
    ">"*) printf 'tier' ;;
    "Off-Peak" | "Peak") printf 'time' ;;
    *) printf 'normal' ;;
  esac
}

# ---------------------------------------------------------------------------
# パース: go.mdx のテーブル抽出
# ---------------------------------------------------------------------------

# 価格テーブルのデータ行 ("| Model | Input | Output | ..." テーブル)
extract_price_rows() {
  awk '
    /^\| Model/ && /Cached Read/ { in_price = 1; next }
    in_price && /^\| -/ { next }
    in_price && /^\| / { print; next }
    in_price { in_price = 0 }
  ' "$1"
}

# 価格テーブルの1行 → JSON エントリ
#   入力: "| Grok 4.5 | $2.00 | $6.00 | $0.30 | - | $15 |"
#   出力: {"id":"grok-4.5","name":"Grok 4.5","note":"normal","input":2.0,...}
#   時間帯 (time) でモード不一致なら何も出力しない
parse_price_row() {
  local row="$1"
  local cells
  IFS='|' read -r -a cells <<<"$row"
  [[ ${#cells[@]} -lt 6 ]] && return 1

  local model note base id kind
  model="$(trim "${cells[1]}")"
  note="$(extract_note "$model")"
  base="$(strip_note "$model")"
  id="$(normalize_model_name "$base")"
  kind="$(classify_note "$note")"
  [[ -z "$id" ]] && return 1

  # 時間帯別価格は Peak 行のみ採用 (Peak 価格で管理する)
  if [[ "$kind" == "time" ]]; then
    [[ "$note" == "Peak" ]] || return 1
  fi

  local input output cr cw above
  input="$(parse_price_cell "$(trim "${cells[2]}")")"
  output="$(parse_price_cell "$(trim "${cells[3]}")")"
  cr="$(parse_price_cell "$(trim "${cells[4]}")")"
  cw="$(parse_price_cell "$(trim "${cells[5]}")")"
  above="$(parse_tier_tokens "$note")"

  jq -nc \
    --arg id "$id" --arg name "$base" --arg kind "$kind" \
    --argjson above "${above:-0}" \
    --argjson input "$input" --argjson output "$output" \
    --argjson cr "$cr" --argjson cw "$cw" '
    {
      id: $id,
      name: $name,
      note: $kind,
      above: $above,
      input: $input, output: $output, cacheRead: $cr, cacheWrite: $cw
    }
  '
}

# 価格テーブル全体 → モデルIDごとの価格マップ JSON
#   出力: {"grok-4.5": {"name":..., "input":..., "output":..., "cacheRead":..., "cacheWrite":..., "tiers": [{...}]?}, ...}
build_price_map() {
  local gomdx="$1"
  local tmp
  tmp="$(mktemp)"
  extract_price_rows "$gomdx" | while IFS= read -r row; do
    parse_price_row "$row" >>"$tmp" || true
  done
  jq -s '
    group_by(.id) | map(
      (first(.[] | select(.note == "normal" or .note == "base")) // .[0]) as $base |
      (first(.[] | select(.note == "tier")) // null) as $tier |
      {
        key: $base.id,
        value: (
          {
            name: $base.name,
            input: $base.input,
            output: $base.output,
            cacheRead: $base.cacheRead,
            cacheWrite: $base.cacheWrite
          }
          + (if $tier then {
              # Pi のスキーマは cost.tiers (配列) を期待する (model-registry.js)
              tiers: [
                {
                  inputTokensAbove: $tier.above,
                  input: $tier.input,
                  output: $tier.output,
                  cacheRead: $tier.cacheRead,
                  cacheWrite: $tier.cacheWrite
                }
              ]
            } else {} end)
        )
      }
    ) | from_entries
  ' "$tmp"
  rm -f "$tmp"
}

# Endpoints テーブルのデータ行 ("| Model | Model ID | Endpoint | ..." テーブル)
extract_endpoint_rows() {
  awk '
    /^\| Model/ && /Model ID/ { in_ep = 1; next }
    in_ep && /^\| -/ { next }
    in_ep && /^\| / { print; next }
    in_ep { in_ep = 0 }
  ' "$1"
}

# Endpoints テーブルの1行 → JSON エントリ
#   入力: "| Grok 4.5 | grok-4.5 | `https://opencode.ai/zen/go/v1/responses` | ..."
#   出力: {"id":"grok-4.5","api":"openai-responses"}
parse_endpoint_row() {
  local row="$1"
  local cells id endpoint api
  IFS='|' read -r -a cells <<<"$row"
  [[ ${#cells[@]} -lt 4 ]] && return 1
  id="$(trim "${cells[2]}")"
  endpoint="$(trim "${cells[3]}")"
  endpoint="${endpoint//\`/}" # バッククォート除去
  case "$endpoint" in
    */responses) api="openai-responses" ;;
    */chat/completions) api="openai-completions" ;;
    */messages) api="anthropic-messages" ;;
    *) return 1 ;;
  esac
  [[ -z "$id" ]] && return 1
  jq -nc --arg id "$id" --arg api "$api" '{($id): $api}'
}

# Endpoints テーブル全体 → モデルID → APIタイプ のマップ JSON
build_api_map() {
  local gomdx="$1"
  local tmp
  tmp="$(mktemp)"
  extract_endpoint_rows "$gomdx" | while IFS= read -r row; do
    parse_endpoint_row "$row" >>"$tmp" || true
  done
  jq -s 'add' "$tmp"
  rm -f "$tmp"
}

# ---------------------------------------------------------------------------
# パース: models.dev のモデルメタデータ
# ---------------------------------------------------------------------------

# models.dev api.json (opencode-go セクション) → モデルメタデータマップ
#   出力: {"grok-4.5": {"contextWindow":500000,"maxTokens":500000,"reasoning":true,"input":["text","image"]}, ...}
build_metadata_map() {
  local api_json="$1"
  # 注意: Pi の models.json スキーマは input が "text" / "image" のみ許可
  # (model-registry.js: input: Type.Optional(Type.Array(Type.Union(["text", "image"]))))
  # models.dev の modalities.input には video / pdf / audio も含まれるため、text/image に絞る
  jq '
    .["opencode-go"].models
    | to_entries
    | map(
        .value as $m |
        {
          key: $m.id,
          value: (
            {
              contextWindow: ($m.limit.context // 0),
              maxTokens: ($m.limit.output // 0),
              reasoning: ($m.reasoning // false),
              input: (
                ($m.modalities.input // [])
                | map(select(. == "text" or . == "image"))
                | if length == 0 then ["text"] else . end
              )
            }
          )
        }
      )
    | from_entries
  ' "$api_json"
}

# メタデータマップから id の JSON を返す (存在しなければ "null")
metadata_for() {
  local metadata="$1" id="$2"
  printf '%s' "$metadata" | jq -c --arg id "$id" '.[$id]'
}

# ---------------------------------------------------------------------------
# 新モデルの推測値
# ---------------------------------------------------------------------------

# 新モデルの contextWindow 推測値 (既知の同系列モデルから推定、未知は pi デフォルト)
guess_context_window() {
  case "$1" in
    glm-5.3) printf '1000000' ;; # GLM-5.2 と同等
    *) printf '128000' ;;
  esac
}

guess_max_tokens() {
  case "$1" in
    glm-5.3) printf '131072' ;; # GLM-5.2 と同等
    *) printf '16384' ;;
  esac
}

# 新モデルの JSON エントリを組み立てる
#   入力: id, name, api, cost JSON, metadata JSON ("null" なら推測値フォールバック)
build_new_model_json() {
  local id="$1" name="$2" api="$3" cost="$4" meta="${5:-null}"
  if [[ "$meta" == "null" ]]; then
    meta="$(jq -nc \
      --argjson cw "$(guess_context_window "$id")" --argjson mt "$(guess_max_tokens "$id")" \
      '{contextWindow: $cw, maxTokens: $mt, reasoning: false, input: ["text"]}')"
  fi
  jq -nc \
    --arg id "$id" --arg name "$name" --arg api "$api" \
    --argjson cost "$cost" --argjson meta "$meta" '
    {
      id: $id, name: $name, api: $api,
      reasoning: $meta.reasoning, input: $meta.input,
      contextWindow: $meta.contextWindow, maxTokens: $meta.maxTokens,
      cost: $cost
    }
  '
}

# ---------------------------------------------------------------------------
# マージ
# ---------------------------------------------------------------------------

# 既存 models.json に価格マップ / APIマップ / メタデータマップをマージして更新後 JSON を stdout に出力
#   - 既存モデル: cost / api / contextWindow / maxTokens / reasoning / input を更新 (他のフィールドは維持)
#   - 新モデル: メタデータ (無ければ推測値) で追加 (models 配列の末尾)
#   - ドキュメント / models.dev から消えた既存モデル: そのまま残す (削除は手動判断)
merge_models() {
  # 注意: "${4:-{}}" は bash の仕様上、末尾に余分な } が付くため if 文でデフォルトを設定する
  local models_path="$1" prices="$2" apis="$3" metadata="${4-}"
  if [[ -z "$metadata" ]]; then metadata="{}"; fi
  local existing_ids new_models id
  existing_ids="$(jq -r '.providers["opencode-go"].models[].id' "$models_path")"

  # 新モデルの JSON 配列を構築
  new_models="[]"
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    if ! grep -qx "$id" <<<"$existing_ids"; then
      local name api cost json meta
      name="$(printf '%s' "$prices" | jq -r --arg id "$id" '.[$id].name')"
      api="$(printf '%s' "$apis" | jq -r --arg id "$id" '.[$id] // ""')"
      cost="$(printf '%s' "$prices" | jq -c --arg id "$id" '.[$id] | {input, output, cacheRead, cacheWrite} + (if .tiers then {tiers} else {} end)')"
      meta="$(metadata_for "$metadata" "$id")"
      json="$(build_new_model_json "$id" "$name" "$api" "$cost" "$meta")"
      new_models="$(printf '%s' "$new_models" | jq --argjson m "$json" '. + [$m]')"
    fi
  done <<<"$(printf '%s' "$prices" | jq -r 'keys[]')"

  jq --argjson prices "$prices" --argjson apis "$apis" --argjson new "$new_models" --argjson meta "$metadata" '
    .providers["opencode-go"].models |= (
      (map(
        . as $m |
        ($prices[$m.id] // null) as $p |
        ($apis[$m.id] // null) as $a |
        ($meta[$m.id] // null) as $mt |
        ({
          id: $m.id,
          name: $m.name,
          api: (if $a then $a else $m.api end),
          reasoning: (if $mt then $mt.reasoning else $m.reasoning end),
          input: (if $mt then $mt.input else $m.input end),
          contextWindow: (if $mt then $mt.contextWindow else $m.contextWindow end),
          maxTokens: (if $mt then $mt.maxTokens else $m.maxTokens end),
          cost: (
            if $p
            then ($p | {input, output, cacheRead, cacheWrite} + (if .tiers then {tiers} else {} end))
            elif ($m.cost | has("tier"))
            # 旧形式 cost.tier (単数) を Pi のスキーマ準拠の cost.tiers (配列) に移行
            then ($m.cost | {input, output, cacheRead, cacheWrite} + { tiers: [.tier] })
            else $m.cost
            end
          )
        }
        + (if ($m | has("compat")) then { compat: $m.compat } else {} end)
        + (if ($m | has("thinkingLevelMap")) then { thinkingLevelMap: $m.thinkingLevelMap } else {} end)
        )
      )) + $new
    )
  ' "$models_path"
}

# ---------------------------------------------------------------------------
# 差分レポート
# ---------------------------------------------------------------------------

# 新モデル / 消えたモデル / 価格・API / メタデータの変化を報告
report_changes() {
  # 注意: "${3:-{}}" は bash の仕様上、末尾に余分な } が付くため if 文でデフォルトを設定する
  local current="$1" merged="$2" metadata="${3-}"
  if [[ -z "$metadata" ]]; then metadata="{}"; fi
  local cur_ids new_ids id
  cur_ids="$(jq -r '.providers["opencode-go"].models[].id' "$current")"
  new_ids="$(jq -r '.providers["opencode-go"].models[].id' <<<"$merged")"

  for id in $new_ids; do
    if ! grep -qx "$id" <<<"$cur_ids"; then
      if [[ "$(metadata_for "$metadata" "$id")" != "null" ]]; then
        echo "   [NEW] ${id} (メタデータは models.dev から取得)"
      else
        echo "   [NEW] ${id} (contextWindow/maxTokens は推測値。要確認)"
      fi
    fi
  done
  for id in $cur_ids; do
    if ! grep -qx "$id" <<<"$new_ids"; then
      echo "   [GONE] ${id} ドキュメントに存在しません。削除するかは手動で判断"
    fi
  done

  # 価格 / API の変化 (数値はセマンティクス比較: 2.0 と 2.00 は同一)
  for id in $cur_ids; do
    if ! grep -qx "$id" <<<"$new_ids"; then
      continue
    fi
    local cur_cost new_cost cur_api new_api
    cur_cost="$(jq -c --arg id "$id" '.providers["opencode-go"].models[] | select(.id == $id) | .cost' "$current")"
    new_cost="$(jq -c --arg id "$id" '.providers["opencode-go"].models[] | select(.id == $id) | .cost' <<<"$merged")"
    if [[ -n "$cur_cost" && -n "$new_cost" ]] && ! jq -en --argjson a "$cur_cost" --argjson b "$new_cost" '$a == $b' >/dev/null 2>&1; then
      echo "   [COST] ${id}: ${cur_cost} -> ${new_cost}"
    fi
    cur_api="$(jq -r --arg id "$id" '.providers["opencode-go"].models[] | select(.id == $id) | .api // ""' "$current")"
    new_api="$(jq -r --arg id "$id" '.providers["opencode-go"].models[] | select(.id == $id) | .api // ""' <<<"$merged")"
    if [[ -n "$cur_api" && -n "$new_api" && "$cur_api" != "$new_api" ]]; then
      echo "   [API] ${id}: ${cur_api} -> ${new_api}"
    fi
  done

  # メタデータ (contextWindow / maxTokens / reasoning / input) の変化
  for id in $cur_ids; do
    if ! grep -qx "$id" <<<"$new_ids"; then
      continue
    fi
    local cur_meta new_meta diff
    cur_meta="$(jq -c --arg id "$id" '.providers["opencode-go"].models[] | select(.id == $id) | {contextWindow, maxTokens, reasoning, input}' "$current")"
    new_meta="$(jq -c --arg id "$id" '.providers["opencode-go"].models[] | select(.id == $id) | {contextWindow, maxTokens, reasoning, input}' <<<"$merged")"
    if [[ -n "$cur_meta" && -n "$new_meta" && "$cur_meta" != "$new_meta" ]]; then
      diff="$(jq -nc --argjson a "$cur_meta" --argjson b "$new_meta" '
        [$a | to_entries[] | .key as $k | select($b[$k] != .value) | "\($k): \(.value) -> \($b[$k])"]
        | join(", ")
      ')"
      echo "   [META] ${id}: ${diff}"
    fi
  done
}

# ---------------------------------------------------------------------------
# テスト用ヘルパー
# ---------------------------------------------------------------------------

price_get() {
  local prices="$1" id="$2" path="$3"
  printf '%s' "$prices" | jq -r --arg id "$id" --arg path "$path" '
    getpath([$id] + ($path | split("."))) // "<missing>"
  '
}

api_get() {
  local apis="$1" id="$2"
  printf '%s' "$apis" | jq -r --arg id "$id" '.[$id] // "<missing>"'
}

# ---------------------------------------------------------------------------
# メイン
# ---------------------------------------------------------------------------

usage() {
  echo "Usage: $(basename "$0") [--check|--apply]"
  echo "  --check    差分検出のみ (デフォルト)。差分ありで exit 1"
  echo "  --apply    models.json を書き込む"
}

main() {
  local mode="check"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check) mode="check" ;;
      --apply) mode="apply" ;;
      -h | --help) usage && return 0 ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        return 2
        ;;
    esac
    shift
  done

  cd "$REPO_ROOT"

  # 1. dirty チェック: 手動編集が未コミットなら上書きしない
  local dirty
  dirty="$(git diff --name-only HEAD -- "${MODELS_PATH}" 2>/dev/null || true)"
  if [[ -n "$dirty" ]]; then
    echo "Skipping: ${MODELS_PATH} has uncommitted changes (manual edit?):" >&2
    printf '%s\n' "$dirty" >&2
    return 10
  fi

  # 2. ネットワーク疎通チェック
  if ! curl -sfI --max-time 5 "${GO_MDX_URL}" -o /dev/null || ! curl -sfI --max-time 5 "${MD_API_URL}" -o /dev/null; then
    echo "Skipping: cannot reach opencode repository or models.dev" >&2
    return 11
  fi

  # 3. go.mdx を取得
  local gomdx
  gomdx="$(mktemp)"
  if ! curl -fsSL --max-time 20 "${GO_MDX_URL}" -o "$gomdx"; then
    echo "Error: failed to fetch go.mdx" >&2
    rm -f "$gomdx"
    return 3
  fi

  # 4. models.dev のメタデータを取得 (失敗時は空マップで続行し既存値 / 推測値を維持)
  local mdjson metadata
  metadata="{}"
  mdjson="$(mktemp)"
  if curl -fsSL --max-time 30 "${MD_API_URL}" -o "$mdjson"; then
    metadata="$(build_metadata_map "$mdjson")"
    if [[ -z "$metadata" || "$metadata" == "{}" ]]; then
      echo "Warning: failed to parse models.dev metadata; keeping existing values" >&2
      metadata="{}"
    fi
  else
    echo "Warning: failed to fetch models.dev; keeping existing values" >&2
  fi
  rm -f "$mdjson"

  # 5. パース
  local prices apis
  prices="$(build_price_map "$gomdx")"
  apis="$(build_api_map "$gomdx")"
  if [[ -z "$prices" || "$prices" == "{}" || -z "$apis" || "$apis" == "{}" ]]; then
    echo "Error: failed to parse go.mdx (empty price/api map). Table structure may have changed." >&2
    rm -f "$gomdx"
    return 4
  fi

  # 6. マージ
  local merged
  merged="$(merge_models "${MODELS_PATH}" "$prices" "$apis" "$metadata")"
  rm -f "$gomdx"

  # 7. 差分チェック (数値はセマンティクス比較: 2.0 と 2.00 は同一扱い)
  if jq -e -n --slurpfile a <(jq -S . "${MODELS_PATH}") --slurpfile b <(jq -S . <<<"$merged") '$a[0] == $b[0]' >/dev/null 2>&1; then
    echo "No changes to ${MODELS_PATH}"
    return 0
  fi

  echo "Changes detected in conf/.pi/agent/models.json (Peak 価格):"
  report_changes "${MODELS_PATH}" "$merged" "$metadata"

  if [[ "$mode" == "apply" ]]; then
    write_atomic "${MODELS_PATH}" "$(jq . <<<"$merged")"
    echo "Applied to ${MODELS_PATH}"
    return 0
  fi
  echo "(Run with --apply to write changes)"
  return 1
}

if [[ "${OPENCODE_SYNC_LIB:-}" != "1" ]]; then
  main "$@"
fi