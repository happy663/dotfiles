---
name: review-loop
description: Codex を相手にした再帰的コードレビューループ。Codex が独立レビュー → Claude が分類 → 反論があれば Codex にメタレビュー → 合意分を修正、を Circuit Breaker 発動まで繰り返す。「Codex とレビューループしたい」「再帰レビュー」「review-loop」等で起動。
argument-hint: "[--base <ref>] [--max-rounds <N>]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
disable-model-invocation: false
---

# Codex とのレビューループスキル

Codex CLI を相手に複数ラウンドのレビュー対話を行い、合意点まで収束させる。

## 前提

- `codex` CLI がインストール済み（`npm install -g @openai/codex`）
- `jq`、`shasum`(または `sha256sum`) が利用可能
- レビュー対象は git 管理下の差分

## 引数

- `--base <ref>` ベース参照。未指定なら `git merge-base HEAD master` を試し、それも失敗したら `HEAD~1`
- `--max-rounds <N>` 最大ラウンド数。既定 3

## ディレクトリ規約

スキル本体: `~/.claude/skills/review-loop/`
作業中の状態: 作業中プロジェクトの `.claude/review-loop/`

```
.claude/review-loop/
├── state.json                       # { round, max_rounds, base_ref, scope_hash, active }
└── rounds/
    └── round-<N>/
        ├── diff.txt                 # ラウンド開始時点の差分
        ├── codex_review.md          # Codex の生レビュー出力（JSON）
        ├── classification.json      # Claude の分類結果
        └── codex_meta.md            # 反論があった場合の Codex のメタレビュー
```

## 実行手順

各ステップで `SKILL_DIR=~/.claude/skills/review-loop` として読み替える。

### 0. 引数を解析して state を初期化

```bash
SKILL_DIR=~/.claude/skills/review-loop
. "$SKILL_DIR/scripts/state.sh"   # ※ 事前に REVIEW_LOOP_DIR を export しておく
```

ループ呼び出し側は事前に：

```bash
export REVIEW_LOOP_DIR="$(git rev-parse --show-toplevel)/.claude/review-loop"
```

を設定する。

base_ref の決定:

```bash
if [[ -n "${BASE_REF:-}" ]]; then
    base="$BASE_REF"
elif base=$(git merge-base HEAD master 2>/dev/null); then
    :
elif base=$(git merge-base HEAD main 2>/dev/null); then
    :
else
    base="HEAD~1"
fi
```

scope-hash は対象ファイル一覧から計算:

```bash
git diff --name-only "$base"..HEAD | "$SKILL_DIR/scripts/scope-hash.sh"
```

state を初期化:

```bash
state_init
state_set round 1
state_set max_rounds "${MAX_ROUNDS:-3}"
state_set base_ref "$base"
state_set scope_hash "$scope_hash"
state_set active 1
```

### 1. ラウンド開始 (Phase 1: Codex 独立レビュー)

a. 現ラウンド番号と作業ディレクトリ取得

```bash
round=$(state_get round)
round_dir=$(state_round_dir "$round")
base=$(state_get base_ref)
```

b. 差分を保存

```bash
git diff "$base"..HEAD > "$round_dir/diff.txt"
```

c. プロンプト組み立て (テンプレート `prompts/initial-review.md` の placeholder を埋める)

placeholders:
- `{{ROUND}}` → 現ラウンド番号
- `{{BASE_REF}}` → base
- `{{SCOPE_DESCRIPTION}}` → `git diff --shortstat "$base"..HEAD` の出力
- `{{PAST_FINDINGS_SECTION}}` → ラウンド1なら「（なし）」、2以降は前ラウンドの未解消findingsをJSONで埋め込む
- `{{DIFF}}` → `cat "$round_dir/diff.txt"` の内容（コードブロック内に展開）

実装メモ: テンプレートはMarkdownで、placeholder は `{{KEY}}` 形式。Claude が直接 Read + Edit で内容を組み立て、Write で完成版を `$round_dir/prompt.md` に保存してから次ステップへ。

d. Codex 実行

```bash
"$SKILL_DIR/scripts/run-codex.sh" "$round_dir/codex_review.md" < "$round_dir/prompt.md"
```

`codex_review.md` には Codex の最終メッセージ（JSON）が保存される。

### 2. findings 分類 (Phase 2)

`prompts/classify-instructions.md` に従って `codex_review.md` の各 finding を分類し、結果を `classification.json` に保存する。

ポイント:
- `decision` を `agree | disagree | compromise | ignore` から選択
- `disagree` / `compromise` 分は次のメタレビューに渡す反論を `rebuttal` に書く
- ユーザー確認は挟まない (auto mode)

### 3. 反論があれば Codex メタレビュー (Phase 3)

`classification.json` から `decision in (disagree, compromise)` の項目を抽出し、`rebuttals` 配列を作る。1件以上あれば `prompts/meta-review.md` を埋めて Codex に投げる。

```bash
rebuttals=$(jq '[.items[] | select(.decision=="disagree" or .decision=="compromise") | {id, rebuttal}]' "$round_dir/classification.json")
if [[ "$(echo "$rebuttals" | jq 'length')" -gt 0 ]]; then
    # meta-review prompt を組み立てて run-codex 実行
    # 結果は $round_dir/codex_meta.md
fi
```

Codex の `responses[]` を読み、`decision` に応じて `classification.json` の各itemを更新:
- `withdraw` → そのitemの status を `closed` に
- `restate` → そのitemの status は `remaining` のまま
- `compromise` → `revised_suggestion` を取り込んで再修正後に `closed`

### 4. 修正の適用 (Phase 4)

`classification.json` で `decision in (agree, compromise)` かつ未適用のitemについて Edit ツールで修正する。修正完了後、各itemに `applied: true` を立てる。

最後に `applied_count` と各itemの `status` を確定させる:
- `applied=true` または `decision=ignore` または Codex が `withdraw` → `closed`
- それ以外 → `remaining`

### 5. Circuit Breaker 判定 → 次ラウンドへ

```bash
state_set round $((round + 1))
if ! "$SKILL_DIR/scripts/circuit-breaker.sh"; then
    # 停止理由が stdout に出る
    reason=$("$SKILL_DIR/scripts/circuit-breaker.sh" 2>&1 || true)
    # 終了処理へ
fi
```

停止しない場合はステップ1へ戻る。停止または `verdict=approved` ならステップ6へ。

### 6. 終了処理

state を片付け、ユーザーに最終サマリを提示:

- 実行ラウンド数
- 累積で適用された修正件数
- 未解消のfindings一覧（あれば人間判断を仰ぐ）
- Circuit Breaker 発動理由（あれば）

```bash
state_set active 0
```

## 出力の規約

- 各ラウンド開始時に「Round N 開始」と一言出す
- Codex の生出力は表示せず、サマリだけ提示する
- 反論を送る前に「以下の反論を Codex に送ります」と要約だけ出す
- 修正の適用は Edit ツールを使い、CLAUDE.md の Pre-Edit Explanation Requirement に従って一括で説明する

## 注意事項

- Codex 呼び出しは `--sandbox read-only` で実行する（レビュー目的なのでCodexが書き込む必要はない）
- 差分が極端に大きい場合は警告のみ出して続行する（Codex 側の context 制限で失敗する可能性はある）
- ループ中に外部から `.claude/review-loop/state.json` を編集された場合の挙動は保証しない
