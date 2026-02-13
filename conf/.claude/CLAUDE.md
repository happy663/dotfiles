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

## Task Completion Behavior

タスク完了時は、Claude Codeのhookシステムが自動的に通知を処理する。
hookの設定は ~/.claude/settings.json で管理される。

### 重要なタスクの完了時

- ファイル編集の完了
- テスト実行の完了
- 分析・検索の完了
- ユーザーの質問への回答完了

これらのイベントはhookシステムによって適切に処理される。

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

### OSS Investigation Policy

**基本原則**: OSSを調査する際は、Web Fetchを使わずghq getでローカルにクローンして調査する

#### ワークフロー

1. **ローカル存在確認**: `ghq list | grep [repo名]`
2. **存在しない場合**: `ghq get [GitHubリポジトリURL]`でクローン
3. **調査実行**:
   - `cd $(ghq root)/github.com/[org]/[repo]`で移動
   - Grep、Read、Globなどの直接ツールで調査

#### 理由

- **全体検索が可能**: コードベース全体をGrep等で検索できる
- **詳細な調査**: Web Fetchの制限を受けずに任意のファイルを読める
- **再利用性**: 一度クローンすれば繰り返し参照可能
- **効率性**: 既存の直接ツールを活用できる

#### 例

```bash
# Neovimプラグインの調査
ghq list | grep nvim-lspconfig
ghq get github.com/neovim/nvim-lspconfig
cd $(ghq root)/github.com/neovim/nvim-lspconfig
# Grep、Readなどで調査
```

### Examples

#### ✅ 効率的なアプローチ

- Issue調査: `gh issue view 10795 --json title,body,comments --jq '{title: .title, body: .body, comments: .comments}`
- リポジトリ確認: `ghq list | grep zgok-ms`
- 設定確認: `Read ~/.gitconfig`

#### ❌ 非効率なアプローチ

- Issue調査にTask tool使用
- 存在確認せずに他リポジトリをTask toolで検索
- 単純な情報取得にTask tool使用

## Plan Mode Behavior

### プラン作成後の動作

プランモードでプランを作成した後、必ず以下の手順を守る：

1. **プランファイルの内容を必ずユーザーに提示する**
2. **ユーザーがプランを確認できるまで待つ**
3. **ExitPlanModeツールを自動的に実行しない**
4. **ユーザーから明示的な承認や実装指示があるまで待機する**

### プラン提示フォーマット

プラン作成完了時は以下のフォーマットで提示する：

```
プランを作成しました。以下の内容をご確認ください：

[プランの詳細内容]

---

このプランで実装を進めてよろしいですか？
承認いただければ実装を開始します。
修正が必要な場合はお知らせください。
```

### 禁止事項

- プラン作成直後にExitPlanModeを実行すること
- ユーザーの確認なしに実装モードへ移行すること
- プランの内容を提示せずに次のステップへ進むこと

## Response Confidence Policy

### 不確実性の明示

**基本原則**: デフォルトで確信度が高いと仮定し、**不確かな情報のみ**明示する

**表示が必要な場合**（確信度60%未満）:

- **[推測]** - 部分的な証拠からの推測（40-60%）
- **[類推]** - 一般的なパターンからの類推（20-40%）
- **[不明]** - 根拠が非常に弱い（20%未満）

**表示が不要な場合**（確信度60%以上）:

- ツール実行結果やファイル確認済みの情報
- 複数の証拠から確認できた情報

**表記**: `**[推測]** 説明文` または `**[類推]** 説明文`

**明示すべき対象**:

- ユーザーの行動判断に影響する情報
- 間違うと問題が起きる情報
- 推奨や選択肢の提示

### 基本方針

1. 即座に回答する
2. 不確かな情報のみ明示する
3. 判断はユーザーに委ねる
4. 迷ったら明示する
