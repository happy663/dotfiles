---
name: request-review
description: 現在の変更内容をCodex（別ターミナル）にレビュー依頼する。git diffを取得し、レビュー観点と共に送信する。
argument-hint: ""
allowed-tools: Bash
disable-model-invocation: false
---

# レビュー依頼スキル

現在のgit変更内容を別ターミナル（Codex）に送信してレビューを依頼します。

## 実行手順

### 1. ターミナル一覧を取得

```bash
nvr --remote-expr 'luaeval("require(\"terminal_bridge\").list_terminals()")'
```

### 2. git diffを取得

```bash
git diff HEAD
```

または、ステージング済みの変更:

```bash
git diff --cached
```

### 3. レビュー依頼を送信

以下の形式でCodex（自分以外のターミナル）に送信する:

```bash
nvr --remote-expr 'luaeval("require(\"terminal_bridge\").external_send(_A)", "{\"target\":<INDEX>,\"command\":\"<REVIEW_PROMPT>\"}")'
```

## レビュー依頼プロンプトのテンプレート

以下の観点でレビューしてください:

1. 可読性 - 変数名・関数名の分かりやすさ、コード意図の伝わり方
2. バグの可能性 - エッジケース考慮、null/undefined処理
3. パフォーマンス - 非効率な処理、不要な再計算
4. セキュリティ - 入力値の検証、機密情報の扱い
5. テスト - テストカバレッジ、テストケースの網羅性

変更内容:
```diff
<GIT_DIFF>
```

問題があれば指摘し、問題なければ「LGTM」と回答してください。
レビュー完了後、send-to-terminal スキルで結果を返してください。

## 注意事項

- git diffが長い場合は要約して送信する
- 複雑なメッセージはjqでJSONエスケープする
- 送信先はCodexが動いているターミナル（通常はindex 2）
