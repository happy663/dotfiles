---
name: watch-latest-comment
description: 作業しているissueで更新された内容を確認する。issueで調査ログを取っている場合、そのログを読みやすい形で出力する。
argument-hint: "[issue番号またはパス]"
allowed-tools: Bash, Read, mcp__acp__Read, Grep
disable-model-invocation: false
---

# Issue最新コメント確認スキル

作業しているissueに追記された内容を確認し、調査ログとして出力しやすい形式で提示します。

## 実行内容

1. **Issue情報の取得**
   - `gh issue view [番号] --comments` でissue全体を取得
   - 最新のコメントを確認

2. **出力形式**
   - issueで調査ログを取っている場合を考慮
   - マークダウン形式で整形
   - コピー&ペーストしやすい形式

## 出力例

```markdown
## 更新内容

[最新コメントの内容]

### 関連情報

- [追加された情報やリンク]
```

## 注意事項

- 調査ログとして記録しやすいよう、構造化された形式で出力
- 必要に応じて、過去のコメントとの関連も示す
