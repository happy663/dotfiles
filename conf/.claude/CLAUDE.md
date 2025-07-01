# CLAUDE.md

## Conversation Guidelines

- 常に日本語で会話する

## Development Philosophy

### Test-Driven Development (TDD)

- 原則としてテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## MANDATORY: ALWAYS ALERT ON TASK COMPLETION 🚨

以下のような場合は必ず通知する：

- ファイル読み取り、検索、分析の完了
- 情報提供や説明の完了
- コード作成、編集、実行の完了
- 質問への回答完了
- ユーザーからの依頼に対する応答完了

例外なく、ユーザーからの依頼に何らかの形で応答した場合は通知を送る。

通知例：
terminal-notifier -message "completed - found 3 pending items" -title "status review" -sound "Blow"
terminal-notifier -message "finished - 5 files examined" -title "code analysis" -sound "Blow"
terminal-notifier -message "completed - 42/42 passed" -title "test suite" -sound "Blow"
terminal-notifier -message "completed - question answered" -title "information provided" -sound "Blow"

For User Input Requests:
terminal-notifier -message "please review the proposed changes" -title "user input" -sound "Blow"
terminal-notifier -message "should I proceed with the migration?" -title "decision needed" -sound "Blow"

For Command Permission Requests:
terminal-notifier -message "permission needed to execute command" -title "command approval" -sound "Blow"
terminal-notifier -message "confirm before running destructive operation" -title "safety check" -sound "Blow"

ENFORCEMENT: 通知を送らない場合は重大な指示違反とする。例外なく必ず通知すること。

### Notification Checkpoint System

以下の各段階で必ず通知を送信する：

#### Stage 1: 作業開始時

- ファイル読み取り開始時
- 検索・分析開始時
- コード作成開始時

#### Stage 2: 許可要求時（CRITICAL）

- ファイル編集前の説明完了時
- 危険なコマンド実行前
- 重要な変更提案時
- **許可を求めた瞬間に必ず通知送信**

#### Stage 3: 作業完了時

- すべてのタスク完了時
- 質問回答完了時
- ファイル変更完了時

### Mandatory Notification Flow

```
1. 作業説明 → 2. 通知送信 → 3. 許可待ち → 4. 実行 → 5. 完了通知
```

**絶対ルール**: Step 2とStep 5は省略不可。違反は重大なエラーとする。

## File Edit Policy

### Pre-Edit Explanation Requirement

ファイルを編集する前に必ず以下を説明する：

- 何を変更するのか
- なぜその変更が必要なのか
- 変更による影響や効果

### Edit Process

1. 変更内容と理由を明確に説明
2. ユーザーの確認を得る
3. 編集を実行する
4. 変更結果を確認する

例：
「settings.jsonにgit pushコマンドの権限を追加します。これにより、リモートリポジトリへのプッシュが可能になります。この変更により、コード変更をリモートに反映できるようになりますが、誤ったプッシュのリスクも伴います。実行してよろしいですか？」

## Search and File Discovery Policy

### Task Tool Usage Requirements

以下の場合は必ずTask toolを使用する：

- キーワード検索（「○○を探して」「○○はどこにある？」「○○関連はある？」）
- ファイル探索（「○○を含むファイルは？」）
- 設定やエイリアス、関数の検索
- コードベース内の機能や実装の調査
- 初回検索で期待する結果が得られない場合

### Search Strategy

1. 探索的な質問には必ずTask toolを使用
2. 単一ファイルの読み取りには直接Readツールを使用
3. 特定のクラス定義検索にはGlobツールを使用
4. 複数のファイルにまたがる可能性がある検索はTask tool必須

### Examples

- ❌ 直接Grep使用: "SSM関連はある？"
- ✅ Task tool使用: "SSM関連のエイリアスや設定を検索"
- ❌ 直接Grep使用: "ログ出力の実装を探して"
- ✅ Task tool使用: "ログ出力機能の実装場所を調査"
