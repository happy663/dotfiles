---
name: send-to-terminal
description: Neovim内の別ターミナル（インデックス指定）にコマンドやメッセージを送信する。Claude CodeとCodex間の双方向通信に使用。
argument-hint: "[message]"
allowed-tools: Bash
disable-model-invocation: false
---

# ターミナル送信スキル

Neovim内の別ターミナルにコマンドやメッセージを送信します。
Claude CodeとCodex間のレビュー依頼やフィードバックに使用できます。

## 実行手順

### 1. 必ず最初にターミナル一覧を取得する

```bash
nvr --remote-expr 'luaeval("require(\"terminal_bridge\").list_terminals()")'
```

結果例:
```json
[{"index":1,"bufnr":10,"name":"term://...claude"},{"index":2,"bufnr":15,"name":"term://...codex"}]
```

### 2. 自分以外のターミナルを特定して送信

- ターミナルが2つの場合: 自分がindex 1なら2へ、自分がindex 2なら1へ送信
- 自分のターミナルは通常、現在実行中のClaude Code/Codexのターミナル

```bash
nvr --remote-expr 'luaeval("require(\"terminal_bridge\").external_send(_A)", "{\"target\":<INDEX>,\"command\":\"<MESSAGE>\"}")'
```

### 3. 複雑なメッセージの場合

改行や特殊文字を含むメッセージは、jqでJSONエスケープする：

```bash
MESSAGE='複数行の
メッセージ'
ESCAPED=$(echo "$MESSAGE" | jq -Rs .)
nvr --remote-expr "luaeval(\"require('terminal_bridge').external_send(_A)\", '{\"target\":2,\"command\":$ESCAPED}')"
```

## 送信先の判断ルール

- ターミナルが2つある場合、自分以外のターミナルに送信する
- 自分がどのターミナルかわからない場合は、ユーザーに確認する
- 引数でインデックスが明示されている場合はそれを使用する

## 使用例

```
# メッセージのみ指定（送信先は自動判断）
send-to-terminal このコードをレビューしてください

# インデックスを明示
send-to-terminal 2 レビュー結果を送ります
```
