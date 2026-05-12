---
description: Codex との再帰的コードレビューループを開始する。Codex が独立レビュー → Claude が分類 → 反論を Codex にメタレビュー → 合意分を修正、を Circuit Breaker まで繰り返す。
argument-hint: "[--base <ref>] [--max-rounds <N>]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

`~/.claude/skills/review-loop/SKILL.md` の手順に従ってレビューループを実行する。

引数:
`$ARGUMENTS`

開始前に必ず以下を確認すること:

1. 現在地が git リポジトリのトップである（`git rev-parse --show-toplevel` で確認）
2. base ref の存在（`git rev-parse --verify <base>`）
3. `codex` CLI が `which codex` で見つかる
4. `.claude/review-loop/` が未使用 or `state.active=0` であること。`active=1` のまま残っている場合はユーザーに「前回の中断状態を破棄して新規開始するか」を確認する

確認が済んだら SKILL.md のステップ0から実行する。各ラウンドの開始・終了時にユーザーへ進捗を1行報告する。
