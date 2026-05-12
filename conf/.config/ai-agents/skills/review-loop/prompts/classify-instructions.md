# findings 分類の指示

Codexから受け取った findings JSON を読み、各findingについて次のいずれかに分類する。
分類は自身の判断で行う（ユーザー確認は挟まない=auto mode）。

## 分類カテゴリ

- `agree`: 指摘が妥当で、コードを修正する
- `disagree`: 指摘に反論する。Codexに meta-review を依頼する
- `compromise`: 部分的に同意。妥協案を持ってCodexに meta-review を依頼する
- `ignore`: 指摘が誤解 / 既存制約と矛盾 / 影響が無視できる、として却下する（理由を記録）

## 判定の方針

- severity=high は原則 agree。明確な誤解がある場合のみ disagree
- severity=nit は文脈で判断。コーディング規約の好みなら ignore も可
- regression として指摘されたものは原則 agree
- 仕様や設計判断に関わるものは compromise を優先（一方的なdisagreeより議論が建設的）

## 出力形式

`classification.json` に保存する。

```json
{
  "round": <int>,
  "items": [
    {
      "id": "f-xxxx",
      "decision": "agree" | "disagree" | "compromise" | "ignore",
      "fix_plan": "agree/compromise の場合の修正方針",
      "rebuttal": "disagree/compromise の場合のCodexへの反論コメント",
      "ignore_reason": "ignore の場合の理由"
    }
  ]
}
```

## 修正の適用

`agree` と `compromise` 分は実際にコードを編集する（Editツール使用）。
修正完了後、`classification.json` の各itemに `applied: true|false` を追記する。
最終的に `applied_count` を items の `applied:true` 件数として書き込む。

## 残存IDの判定

ループ継続判定 (circuit-breaker) のため、各itemに `status` を以下のルールで設定する。

- `applied=true` → `status: "closed"`
- `applied=false` かつ `decision=ignore` → `status: "closed"`
- それ以外 → `status: "remaining"`

最終的な `classification.json` は次の形式になる（circuit-breakerが読む形式）。

```json
{
  "round": <int>,
  "applied_count": <int>,
  "items": [
    {"id": "f-xxxx", "decision": "...", "applied": true|false, "status": "closed"|"remaining", ...}
  ]
}
```
