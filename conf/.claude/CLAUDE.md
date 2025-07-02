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

### Efficiency-First Tool Selection

**速度優先の原則**: 直接的なツールを優先し、Task toolは本当に必要な場合のみ使用する

#### Direct Tools (Fast) - 優先使用
- `gh issue view [番号] --comments`: GitHub issue情報
- `ghq list | grep [repo名]`: ローカルリポジトリ存在確認
- `Read`: 特定ファイルの内容確認
- `Grep`: 明確なパターン検索
- `Glob`: 特定のファイル名/拡張子検索

#### Task Tool (Slower) - 限定使用
以下の場合のみTask toolを使用する：

- **真の探索的調査**: 何があるか全く分からない場合
- **複雑な多段階検索**: 複数の条件を組み合わせた調査
- **初回の全体把握**: 新しいコードベースの概観把握

### Repository Investigation Workflow

1. **Issue調査**: `gh issue view [番号] --comments`で全情報を一括取得
2. **他リポジトリ調査が必要な場合**:
   - `ghq list | grep [repo名]`でローカル存在確認
   - 存在すれば`cd $(ghq root)/github.com/[org]/[repo]`で移動
   - 直接ツールで調査実行
3. **存在しない場合**: リポジトリクローンが必要と報告

### Examples

#### ✅ 効率的なアプローチ
- Issue調査: `gh issue view 10770 --comments`
- リポジトリ確認: `ghq list | grep zgok-ms`
- 設定確認: `Read ~/.gitconfig`

#### ❌ 非効率なアプローチ
- Issue調査にTask tool使用
- 存在確認せずに他リポジトリをTask toolで検索
- 単純な情報取得にTask tool使用
