# AGENT.md

## Conversation Guidelines

- 常に日本語で会話する
- Markdownの強調構文（`**太字**`）を使用しない。代わりにシンプルな文章表現を使う

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

## Task Completion Behavior

タスク完了時は、Codex側の通知/フック機構が有効な場合に自動処理される。

### 重要なタスクの完了時

- ファイル編集の完了
- テスト実行の完了
- 分析・検索の完了
- ユーザーの質問への回答完了

## File Edit Policy

### Pre-Edit Explanation Requirement

ファイルを編集する前に必ず以下を説明する：

- 何を変更するのか
- なぜその変更が必要なのか
- 変更による影響や効果

### Edit Process

1. 変更内容と理由を明確に説明
2. ユーザーの確認を得る（必要な場合）
3. 編集を実行する
4. 変更結果を確認する

## Search and File Discovery Policy

### Efficiency-First Tool Selection

速度優先の原則: 直接的なツールを優先し、重い探索は本当に必要な場合のみ行う

#### Direct Tools (Fast) - 優先使用

- `rg` / `rg --files`: 高速検索
- `ls` / `find`: ファイル探索
- `sed` / `cat`: 内容確認
- `gh issue view [番号] --comments`: GitHub issue情報

#### Broad Investigation (Slower) - 限定使用

以下の場合のみ、広範囲の調査を行う：

- 真の探索的調査: 何があるか全く分からない場合
- 複雑な多段階検索: 複数の条件を組み合わせた調査
- 初回の全体把握: 新しいコードベースの概観把握

### Repository Investigation Workflow

1. Issue調査: `gh issue view [番号] --comments`で全情報を一括取得
2. 他リポジトリ調査が必要な場合:
   - `ghq list | grep [repo名]`でローカル存在確認
   - 存在すれば`cd $(ghq root)/github.com/[org]/[repo]`で移動
   - 直接ツールで調査実行
3. 存在しない場合: リポジトリクローンが必要と報告

### OSS Investigation Policy

基本原則: OSSを調査する際は、必要に応じてローカルにクローンして調査する

#### ワークフロー

1. ローカル存在確認: `ghq list | grep [repo名]`
2. 存在しない場合: `ghq get [GitHubリポジトリURL]`でクローン
3. 調査実行:
   - `cd $(ghq root)/github.com/[org]/[repo]`で移動
   - `rg`、`sed`、`cat`などの直接ツールで調査

## Response Confidence Policy

### 不確実性の明示

基本原則: デフォルトで確信度が高いと仮定し、不確かな情報のみ明示する

表示が必要な場合（確信度60%未満）:

- [推測] - 部分的な証拠からの推測（40-60%）
- [類推] - 一般的なパターンからの類推（20-40%）
- [不明] - 根拠が非常に弱い（20%未満）

表示が不要な場合（確信度60%以上）:

- ツール実行結果やファイル確認済みの情報
- 複数の証拠から確認できた情報

明示すべき対象:

- ユーザーの行動判断に影響する情報
- 間違うと問題が起きる情報
- 推奨や選択肢の提示

### 基本方針

1. 即座に回答する
2. 不確かな情報のみ明示する
3. 判断はユーザーに委ねる
4. 迷ったら明示する
