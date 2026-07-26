---
name: log-ai-conversation-detailed
description: AIとの会話を、ユーザーの思考メモ(Self)も含めてGitHub IssueまたはPull Requestにコメントとして追加する実験版。手動で呼び出して使用。
allowed-tools: Bash, Read, Write, mcp__acp__Read, WebFetch
argument-hint: "[--confirm]"
disable-model-invocation: true
---

# AIとの会話をGitHubに詳しくログする

現在の会話をまとめて、GitHub IssueまたはPull Requestにコメントとして追加します。
通常版よりも「ユーザーが何をどう考えたか」を残すことを重視し、必要に応じて `Self` セクションを含めます。

## 呼び出され方

このスキルは以下のいずれかで呼ばれます:

* 手動で `/log-ai-conversation-detailed` を実行（フォアグラウンド実行）

呼び出し元のUIやエディタに依存せず、スキル本体の処理は同じです。

## 対象の会話

* 現在のセッションで交わされた会話を対象にする
* 「前回どこまで記録したか」は状態として管理しない
* 代わりに、直前の GitHub コメントを確認し、内容が重複しないようサマリー作成時に判断する
* セッションを跨いで同じ Issue/PR にログする場合も、直前コメントの確認で重複を回避する

## 投稿先の特定

1. 会話文脈からIssue/PRのどちらへ残すべきかを推定する
2. 推定できない場合は、ユーザーにリポジトリ、出力先種別（Issue/PR）、番号を確認する

判断基準:

* Issueにコメントする: 調査ログ、作業方針、未着手タスク、問題整理、issue本文やissueコメントに紐づく会話
* PRにコメントする: 実装済み変更の説明、レビュー対応ログ、CI修正、PRレビューコメントに紐づく会話
* 迷う場合: コメント投稿前の確認ステップで、Issue/PRどちらに投稿するかを明示してユーザーに確認する

## サマリー作成

### 詳細版の目的

この実験版では、AI側の調査・判断・実装ログだけでなく、ユーザーが会話中に出した以下のような内容も記録対象にする:

* 要求そのものではなく、独り言・違和感・理解の途中経過に近い発言
* AIの説明や提案を受けて、ユーザーが何を気にしたか
* 意思決定の前提になったユーザー側の判断軸
* 後からIssue/PRを読んだ人が「なぜその方向に進んだのか」を理解するために必要な思考メモ

ただし、全会話の逐語録にはしない。目的はプロンプト全文の保存ではなく、意思決定の理解に必要なユーザーの思考を残すこと。

### まとめ方

* 作業ログ形式（時系列・試行錯誤・主観表現OK）
* トピックごとに `## {トピック}` で見出しをつける
* 1セクション（= 1トピック） = 1コメント = 1ファイル で投稿する。1セッションで複数コメントになることは問題ない（文章を読む量は変わらない）
* 「問題→調査→試行→結果」の流れを意識する
* 直前のコメントを確認し、前のコメントと内容が重複しないよう・話の流れが自然につながるよう意識する

### Selfセクション

ユーザーの思考メモ・違和感・理解の途中経過・補足が意思決定の理解に重要な場合、該当セクションの末尾に `### Self` を追加する。

* 1セッション = 複数コメント構成なので、Self は各セクション（コメント）ごとに用意する。まとめとしての `## Self` は作らない
* 必ず追加するのではなく、記録する価値がある場合だけ追加する
* 空欄や薄いSelfを作らない

`Self` には、ユーザーの発言を原文のまま長く引用せず、ユーザーの言葉遣い・迷い・違和感をできるだけ保って短く再構成する。

書くべき内容:

* ユーザーが何を気にしていたか
* どの説明で理解が進んだか
* どの点に違和感を持ったか
* どの判断軸を重視したか
* AIの提案に対して、ユーザーが採用・保留・修正した理由

書かない内容:

* 認証情報、トークン、秘密情報
* 個人攻撃、社内の人間関係の評価、感情的な愚痴
* GitHub Issue/PR の読者に不要な私的事情
* ユーザーが「これは残さないで」と言った内容
* プロンプト全文の逐語記録

`Self` は「ユーザーの内面を全部記録する場所」ではなく、「意思決定の理解に必要な思考メモ」を残す場所として扱う。

### 詳細度の基準

省略しすぎない。以下の要素を含めることをデフォルトとする:

* 問題の背景と原因: なぜ発生するのか、根本原因の説明
* 設計判断: なぜその方式を選んだのか、他の選択肢との比較
* 実装の要点: 主要な関数・処理フローをコード付きで説明。処理の流れが複雑な場合はASCII図も使う
* 途中で踏んだ問題: デバッグ過程、試行錯誤、失敗とその原因
* 副作用・トレードオフ: 既存動作への影響、残課題

「後から読み返して、何をなぜどうやったか再現できる」レベルを目指す。要約ではなく記録。

### 重複の回避手順

1セッションで複数コメントを投稿するため、重複判定は「セクション単位」で行う。

1. 直近のコメント（既に投稿済みの自コメント含む）を取得する。セクションごと投稿なので、前回セッション分も含めて遡って確認する
2. 今回の会話で新しく出てきたトピックを特定する
3. 既存コメントと今回書く内容を見比べ、重複しているセクションを特定する
   * 同じトピックについて書かれているか
   * 新しい情報が増えているか
4. 重複しているセクションは投稿しない。新規セクションだけを1セクション=1コメントで投稿する
   * 既存セクションに新規情報があれば、そのセクションを新規コメントとして再投稿するのではなく、追記すべきか別途判断する

直前コメントの確認コマンド:

```bash
# Issueの場合（直近2件）
gh issue view {number} --repo {owner/repo} --json comments --jq '.comments[-2:]'

# PRの場合（直近2件）
gh pr view {number} --repo {owner/repo} --json comments --jq '.comments[-2:]'
```

## コード参照ルール

### 30行未満のコード

コードブロック + GitHub permalinkを併記する:

```lua
-- コード内容
```

<https://github.com/{owner}/{repo}/blob/{commit}/{path}#L{start}-L{end}>

### 30行以上のコード

permalinkのみを`<details>`で折りたたむ:

<details>
<summary>コードを見る ({行数}行)</summary>

<https://github.com/{owner}/{repo}/blob/{commit}/{path}#L{start}-L{end}>

</details>

### リポジトリ外の調査資産（permalink が作れない素材）

上記2ルールはリポジトリ内コード（permalink 可能）前提。一方、調査で使った一時的な probe スクリプト（`/tmp` 等）や実測ログ、外部プラグイン（NvimTree 等）のコード断片は permalink が作れない。これらは本文の理解に必須でなければ、`<details>` で「補助情報」として載せてよい:

<details>
<summary>{素材の名前}（再現probe / 実測ログ / 外部プラグイン該当箇所）</summary>

```lua
-- probeのコード等
```

</details>

制約:

* 本文は details を読まなくても完結すること（結論と要約は本文に書く）
* details は「再現したい人向けの素材」に限る（probe コード、生実測ログ、外部プラグインの該当箇所など）
* 「何でも details に放り込んで本文が薄くなる」のを避ける。本文に必要なものは本文に書く

## permalinkの生成方法

```bash
# コミットハッシュを取得
git log -1 --format='%H' -- {file_path}

# リモートURLからowner/repoを取得
git remote get-url origin | sed 's|.*github.com[:/]||' | sed 's|\.git$||'
```

## コメント追加方法

### セクションごとの投稿・ファイル作成（核心）

1セッションで記録するトピックが複数ある場合、各セクション（トピック）ごとに:

1. 専用のファイルを作る（1セクション = 1ファイル）
2. そのファイルで1コメントを投稿する（1セクション = 1コメント）

を繰り返す。1ファイルに全セクションを詰め込んで1コメントで投稿することはしない。

### 確認モード（引数で切り替え）

* デフォルト（確認なし）: 各セクションをファイルに書き出し、パスを提示して即座に投稿する
* `--confirm` 指定時（確認あり）: ファイルに書き出し、パスを提示したあと、ユーザーの承認を得てから投稿する

引数の判定は `args` に `--confirm` が含まれているかで行う。

### 本文のファイル出力（必須・確認の有無に関わらない）

コメント本文は必ず一時ファイルに書き出す。エスケープの罠（バックティック・`$` 展開）を構造的に回避するため、`gh` にはファイル経由（`-F`）で渡す。HEREDOCは使わない。

ファイルはセクションごとに作成し、命名は「連番2桁 + slug」とする:

```bash
# type: issue | pr, NN: 連番2桁(01, 02, ...), slug: セクション見出しの英語短縮形
body_file="/tmp/log-ai-conversation-${type}-${number}-${NN}-${slug}.md"
# 例: /tmp/log-ai-conversation-issue-123-01-cache-prerequisite.md
```

slugの生成（ゆるい指針）:
* セクション見出し（`## {トピック}`）を英語短语に訳し、ハイフン結合する
* 3-5語程度に短縮する
* 例: 「キャッシュが効く/効かないを決める6条件」→ `cache-hit-conditions`
* slug生成に迷ったり失敗した場合は、連番だけでも一意性は担保されているのでslug省略可（`-01.md`）

本文の書き出しは Write ツールで行う。

### ファイルパスの提示（必須・確認の有無に関わらない）

書き出した本文ファイルのパスをチャットに提示する。複数セクションある場合は全ファイルのパスを提示する。

```
コメント本文:
- /tmp/log-ai-conversation-issue-123-01-cache-prerequisite.md
- /tmp/log-ai-conversation-issue-123-02-dry-run.md
- /tmp/log-ai-conversation-issue-123-03-actual-measurement.md
```

### 投稿の実行

セクションごとにファイルを作成→投稿を繰り返す。確認モードに応じて実行タイミングを切り替える:

* デフォルト: 各ファイル書き出し・パス提示後、即座に実行（セクションごとに逐次）
* `--confirm`: ユーザーに「これらのNコメントを{Issue/PR} #{number} に追加してよいですか？」と確認し、承認した場合のみ実行

```bash
# Issueの場合（セクションごとに実行）
gh issue comment {number} --repo {owner/repo} -F "${body_file}"

# PRの場合（セクションごとに実行）
gh pr comment {number} --repo {owner/repo} -F "${body_file}"
```

投稿後は各コメントの投稿先URLとファイルパスを併せて提示する。ファイルは投稿後も残す。

## 出力例

以下はlazygitのworktree操作についてAIと会話した内容を、セクションごとに分けて投稿する例です。1セッションで3トピック → 3ファイル → 3コメントになります。

### コメント1（ファイル: `/tmp/log-ai-conversation-issue-123-01-worktree-view.md`）

````markdown
## lazygitでworktree viewが表示されない

lazygitでworktree viewが表示されない問題を調査した。

設定ファイルを確認したところ、`]`/`[`でタブ移動してWorktreesタブへアクセスできることがわかった。
また、設定ファイルにtypoがあることも発見した。

```yaml
screenMode: "normal"  # "nomarl" から修正
```
https://github.com/happy663/dotfiles/blob/xxx/conf/.config/lazygit/config.yml#L6

参考:
- https://raw.githubusercontent.com/jesseduffield/lazygit/master/docs/keybindings/Keybindings_ja.md

### Self

最初は「lazygitでworktree viewが表示されない」と考えていたが、調査を進める中でタブ移動の見落としと設定typoを分けて確認する必要があると整理した。
Neovim経由で起動しているため、lazygit単体の挙動だけでなく、終了後に親プロセスへcwdをどう反映するかも別の論点として扱う必要がある。
````

### コメント2（ファイル: `/tmp/log-ai-conversation-issue-123-02-cwd-sync.md`）

````markdown
## lazygit終了後にworktreeのディレクトリが反映されない

Neovim経由でlazygitを使っているため、lazygit内でworktreeを切り替えても親シェルのcwdは変わらない。
次回起動時に元のディレクトリから始まってしまう問題があった。

`LAZYGIT_NEW_DIR_FILE`を使ってlazygit終了時にNeovimのcwdを同期する処理を追加した。

```lua
local lazygit_new_dir_file = vim.fn.stdpath("state") .. "/lazygit-newdir"
vim.env.LAZYGIT_NEW_DIR_FILE = lazygit_new_dir_file

local function sync_cwd_from_lazygit()
  if vim.fn.filereadable(lazygit_new_dir_file) ~= 1 then
    return
  end
  local lines = vim.fn.readfile(lazygit_new_dir_file)
  pcall(vim.fn.delete, lazygit_new_dir_file)
  local new_dir = lines[1]
  if not new_dir or new_dir == "" or vim.fn.isdirectory(new_dir) ~= 1 then
    return
  end
  vim.cmd("cd " .. vim.fn.fnameescape(new_dir))
end
```
https://github.com/happy663/dotfiles/blob/xxx/conf/.config/nvim/lua/plugins/git/lazygit.lua#L20-L37

qで終了すると反映され、Shift+Qだと反映しない。
````

### コメント3（ファイル: `/tmp/log-ai-conversation-issue-123-03-worktree-vs-branch.md`）

````markdown
## worktreeとbranchの違いがわからなかった

「同じmainを複数worktreeで同時checkoutできない」の意味が最初わからなかった。

何度か質問して理解した内容:
- worktreeは「作業ディレクトリ」を増やすもの
- branchは「履歴の線」で、worktreeごとに1つチェックアウトする
- 同じブランチ名を複数worktreeで同時に使うことはGitが禁止している

つまり:
- OK: ~/dotfiles = main, ~/dotfiles-wt = feat/x
- OK: ~/dotfiles = main, ~/dotfiles-wt = detached(mainのコミット)
- NG: ~/dotfiles = main, ~/dotfiles-wt = main

### Self

「同じmainを複数worktreeで同時checkoutできない」の意味が最初わからず、worktreeとbranchを混同していた。何度か質問して「作業ディレクトリ」と「履歴の線」を分けて整理できたことが理解の転機。
````
