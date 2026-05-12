# review-loop

Codex を相手にした再帰的コードレビューループのスキル。

## 何ができるか

`/review-loop` を叩くと、Claude Code がオーケストレーターとして以下を繰り返す。

```
Round 1
  Codex 独立レビュー    → findings (JSON)
  Claude 分類           → agree / disagree / compromise / ignore
  Codex メタレビュー    → withdraw / restate / compromise
  Claude 修正適用       → applied / remaining
Round 2  (前回未解消が残っていれば)
  ...
Circuit Breaker 発動 or verdict=approved で終了
```

3つの停止条件:
- max_rounds 超過
- 連続2ラウンドで修正0件 (no_progress)
- 同じ指摘IDが3ラウンド連続で残存 (persistent_disagreement)

## ファイル構成

```
review-loop/
├── SKILL.md                       # スキル本体（Claude が読む手順書）
├── README.md                      # このファイル
├── scripts/
│   ├── state.sh                   # 状態ファイル read/write
│   ├── scope-hash.sh              # 対象ファイル群のハッシュ計算
│   ├── circuit-breaker.sh         # 停止条件判定
│   └── run-codex.sh               # codex exec の薄いラッパー
├── prompts/
│   ├── initial-review.md          # Phase 1: Codex 独立レビュー用
│   ├── meta-review.md             # Phase 3: 反論への再評価用
│   └── classify-instructions.md   # Phase 2: Claude 分類の指示
└── tests/                         # bash テスト
    ├── _assert.sh
    ├── run-all.sh
    ├── test_scope_hash.sh
    ├── test_state.sh
    └── test_circuit_breaker.sh
```

## テストの実行

```bash
bash tests/run-all.sh
```

## 関連スキル / プラグイン

- alecnielsen/adversarial-review — 4フェーズdebateループの元ネタ
- hamelsmu/claude-review-loop — Stop hook で自動継続する1往復型
- Mauritiusllewelynpowys919/codex-review — round tracking のコンセプト元

## 起動方式

v0.1 では `/review-loop` スラッシュコマンドからの起動のみ。Claude Code が SKILL.md の手順に従って1セッション内でループを回す。

v0.2 で Stop hook によるセッション跨ぎ継続を予定。
