---
name: send-review-result
description: レビュー結果をClaude Code（別ターミナル）に送信する。Codexでのレビュー完了後に使用。
argument-hint: ""
allowed-tools: Bash
disable-model-invocation: false
---

# レビュー結果送信スキル

レビュー結果をClaude Code（別ターミナル）に送信する。

## 実行手順

### 1. 専用スクリプトで送信する

```bash
bash conf/.config/ai-agents/skills/send-review-result/scripts/send_review_result.sh "<REVIEW_RESULT>"
```

Codex から実行する場合、macOS の sandbox では `nvr` 接続が失敗することがある。
その場合は最初から権限付きでこのスクリプトを実行する。

引数を省略した場合は以下を自動送信する:

```md
## レビュー結果

### 総評
LGTM
```

### 2. 必要に応じて送信先を上書きする

```bash
SEND_REVIEW_RESULT_TARGET=2 bash conf/.config/ai-agents/skills/send-review-result/scripts/send_review_result.sh "<REVIEW_RESULT>"
```

`SEND_REVIEW_RESULT_SERVER` を指定すると、接続先サーバーを固定できる。

## スクリプトの動作

- `SEND_REVIEW_RESULT_SERVER` -> `$NVIM` -> `~/.cache/nvim/server.pipe` の順で接続を試行する
- どれも失敗した場合のみ `nvr --serverlist` で探索する
- `target` は既定で `1`（Claude Code想定）
- 改行や引用符を含むメッセージは内部でJSONエスケープして送信する
- `nvr` が `Operation not permitted` や `failed to attach` を返した場合は、sandbox 起因の可能性を案内する

## レビュー結果フォーマット

以下の形式を推奨する:

```md
## レビュー結果

### 総評
[LGTM / 要修正 / 要検討]

### 指摘事項
1. [指摘内容と理由]
2. [指摘内容と理由]

### 良い点
- [良い点があれば記載]

### 推奨事項
- [あれば記載]
```

## 運用メモ

- 問題がない場合は「LGTM」と総評のみでよい
- Codex + macOS では `nvr` が sandbox からソケットに接続できないことがある。その場合は `send_review_result.sh` を権限付きで実行する
- ユーザー確認を減らすには、`bash conf/.config/ai-agents/skills/send-review-result/scripts/send_review_result.sh` の実行許可を事前承認しておく
