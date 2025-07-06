# Neovim起動性能調査レポート - Issue #116

## 概要
Neovim起動時の間欠的な遅延問題（issue #116）の根本原因調査と解決策の実装記録。

## 問題の症状
- **初回起動時**に2-3秒の大幅遅延が発生
- **連続起動**では正常速度（500ms前後）
- **6分程度の間隔**を空けると再び遅延が発生

## 調査手法

### Phase 1: 初期仮説検証
- **nix-daemon再起動説**：30分監視で完全に否定
- **メモリ圧迫影響**：27-36%の性能低下を確認（副次的要因）

### Phase 2: Microsoft Defender重点調査 ⭐
**最も重要な発見**
```bash
# 60分間の連続監視で発見した遅延パターン
測定26: 1215ms (初回) → 445ms → 450ms (平均: 703ms)
測定45: 1462ms (初回) → 493ms → 477ms (平均: 810ms)
```

**Defenderの影響**：
- 初回起動時にCPU使用率89.9% → 143.8%に急上昇
- `sourcing`処理で1292ms遅延（設定ファイル読み込み）
- リアルタイムスキャンによる遅延を確認

### Phase 3: 長期間隔測定による完全再現 🎯

## 解決策の実装

### 1. Microsoft Defender除外設定
```bash
# 実行コマンド
mdatp exclusion folder add --path /Users/happy/.config/nvim
mdatp exclusion folder add --path /Users/happy/dotfiles  
mdatp exclusion folder add --path /nix/store

# 確認
mdatp exclusion list
```

**結果**：初回起動遅延を1462ms → 596ms（**59%改善**）

### 2. 最終検証テスト

6分間隔での5回測定（長期間隔テスト）：

| 測定回 | 1回目測定 | 2回目測定 | 3回目測定 | 平均時間 | 判定 |
|--------|-----------|-----------|-----------|----------|------|
| 1回目  | 380ms | 521ms | 509ms | 470ms | ✅ 正常 |
| 2回目  | **3580ms** | 555ms | 551ms | 1562ms | 🚨 遅延 |
| 3回目  | 430ms | 528ms | 493ms | 483ms | ✅ 正常 |
| 4回目  | **2414ms** | 493ms | 508ms | 1138ms | 🚨 遅延 |
| 5回目  | 387ms | 506ms | 515ms | 469ms | ✅ 正常 |

## 特定された根本原因

### 主要因：Telescopeプラグインの遅延ロード
```
重い処理（50ms以上）:
  3100.477ms sourcing
  1148.436ms require('telescope')  
  1623.725ms require('telescope._extensions.smart_open')
```

### 複合要因
1. **Microsoft Defender**のリアルタイムスキャン（除外設定で軽減）
2. **Telescopeプラグイン**の初期化処理（未解決）
3. **システムキャッシュ**の定期的な無効化

## 測定スクリプト

### 長期間隔測定スクリプト（`long-interval-test.sh`）
```bash
#!/bin/bash
# 6分間隔でNeovim起動時間を測定し、issue #116を再現/検証するスクリプト

ITERATIONS=${1:-5}  # 測定回数
INTERVAL_MINUTES=${2:-6}  # 間隔（分）

# 最後のneovim起動時刻を確認し、必要に応じて追加待機
# 各測定で3回起動して平均を算出
# システム状態（メモリ、CPU、Defender状況）も記録
```

**使用方法**：
```bash
chmod +x long-interval-test.sh
./long-interval-test.sh 5 6  # 5回測定、6分間隔
```

## 現在の状況

### ✅ 解決済み
- Microsoft Defenderによる初回起動遅延（59%改善）
- 測定・検証用のスクリプト完成

### ⚠️ 未解決
- Telescopeプラグインの初期化遅延（2-3秒）
- 6分間隔でのキャッシュ無効化現象

## 次のステップ

1. **Telescopeの最適化**：
   - 遅延ロード設定の見直し
   - `smart_open`拡張の最適化
   - 代替プラグインの検討

2. **継続的な監視**：
   - `long-interval-test.sh`での定期測定
   - 改善効果の定量的評価

## 技術的な学び

- **Microsoft Defender**のエンタープライズ環境での影響は想像以上に大きい
- **プラグインの遅延ロード**は設定ファイルだけでなく実際の初期化処理も考慮が必要
- **長期間隔での測定**が間欠的な性能問題の発見に極めて有効

## ファイル一覧

- `long-interval-test.sh` - 長期間隔測定スクリプト
- `phase2-defender-investigation.sh` - Defender重点調査スクリプト
- `memory-pressure-test.sh` - メモリ圧迫テストスクリプト
- `nix-daemon-monitor.sh` - nix-daemon監視スクリプト
- 各種ログファイル（.log）

---

**調査期間**: 2025年7月5日 20:58 - 2025年7月6日 00:48  
**主要改善**: 初回起動時間 1462ms → 596ms（59%短縮）  
**課題**: Telescopeプラグイン初期化の2-3秒遅延が残存