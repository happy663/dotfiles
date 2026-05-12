# 反論への再評価依頼 (Round {{ROUND}})

前ラウンドであなたが指摘した内容に対し、実装側（Claude）から反論が届いた。各反論を読んで判定する。

## 反論

```json
{{REBUTTALS_JSON}}
```

各 `rebuttals[]` には:
- `id`: 元findingのID
- `rebuttal`: Claudeからの反論コメント（なぜ修正しないか / 修正方針が違うと考える理由）

## 判定ルール

各IDについて、次の3択で判定する。

- `withdraw`: 反論に納得した。指摘を取り下げる
- `restate`: 反論には同意できない。元の指摘を維持する（必要なら表現を強化）
- `compromise`: 部分的に同意。新しい妥協案を提示する

## 出力形式（厳守）

最終メッセージは以下のJSONのみを返す。

```json
{
  "round": {{ROUND}},
  "responses": [
    {
      "id": "f-xxxx",
      "decision": "withdraw" | "restate" | "compromise",
      "reasoning": "判定理由",
      "revised_suggestion": "compromise の場合のみ、新しい提案"
    }
  ]
}
```
