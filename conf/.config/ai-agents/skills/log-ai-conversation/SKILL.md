---
name: log-ai-conversation
description: AIとの会話をまとめてGitHub IssueまたはPull Requestにコメントとして追加する。手動で呼び出して使用。
allowed-tools: Bash, Read, Write, mcp__acp__Read, WebFetch
argument-hint: "[--confirm]"
disable-model-invocation: false
---

# AIとの会話をGitHubにログする

現在の会話をまとめて、GitHub IssueまたはPull Requestにコメントとして追加します。

## 呼び出され方

このスキルは以下のいずれかで呼ばれます:

* 手動で `/log-ai-conversation` を実行（フォアグラウンド実行）
* `AgentClaudeLogConversation` コマンド経由で fork 先セッション内で実行（バックグラウンド実行）

後者の場合、メインセッションは fork 先を分割ペインで起動した直後に会話を継続できます。fork 先はこのスキルを実行し、完了後も終了せずペインに残ります（ユーザーが確認後に閉じる）。いずれの呼び出しでも、スキル本体の処理は同じです。

## 対象の会話

* 現在のセッションで交わされた会話を対象にする
* 「前回どこまで記録したか」は状態として管理しない
* 代わりに、直前の GitHub コメントを確認し、内容が重複しないようサマリー作成時に判断する
* セッションを跨いで同じ Issue/PR にログする場合も、直前コメントの確認で重複を回避する

## 投稿先の特定

1. Octoバッファ（`octo://`で始まるバッファ）が開いている場合
   * バッファの種類（Issue/PR）と番号を文脈から推定する
   * ユーザーに出力先（Issue/PR、番号、リポジトリ）を確認する
2. Octoバッファがない場合
   * 会話文脈からIssue/PRのどちらへ残すべきかを推定する
   * 推定できない場合は、ユーザーにリポジトリ、出力先種別（Issue/PR）、番号を確認する

判断基準:

* Issueにコメントする: 調査ログ、作業方針、未着手タスク、問題整理、issue本文やissueコメントに紐づく会話
* PRにコメントする: 実装済み変更の説明、レビュー対応ログ、CI修正、PRレビューコメントに紐づく会話
* 迷う場合: コメント投稿前の確認ステップで、Issue/PRどちらに投稿するかを明示してユーザーに確認する

## サマリー作成

### まとめ方

* 作業ログ形式（時系列・試行錯誤・主観表現OK）
* トピックごとに `### {トピック}` で見出しをつける
* 1コメント = 1まとまり
* 「問題→調査→試行→結果」の流れを意識する
* 直前のコメントを確認し、前のコメントと内容が重複しないよう・話の流れが自然につながるよう意識する

### 詳細度の基準

省略しすぎない。以下の要素を含めることをデフォルトとする:

* 問題の背景と原因: なぜ発生するのか、根本原因の説明
* 設計判断: なぜその方式を選んだのか、他の選択肢との比較
* 実装の要点: 主要な関数・処理フローをコード付きで説明。処理の流れが複雑な場合はASCII図も使う
* 途中で踏んだ問題: デバッグ過程、試行錯誤、失敗とその原因
* 副作用・トレードオフ: 既存動作への影響、残課題

「後から読み返して、何をなぜどうやったか再現できる」レベルを目指す。要約ではなく記録。

### 重複の回避手順

1. 直前のコメント（ユーザー/AI問わず）を取得する
2. 今回の会話で新しく出てきたトピックを特定する
3. 前回のコメントと今回書く内容を見比べ、重複している箇所を特定する
   - 同じトピックについて書かれているか
   - 新しい情報が増えているか
4. 重複しているトピックは除外、新規トピックだけを書く
   - 新規情報があれば、そのトピック内に追記するか、新規見出しで扱う

直前コメントの確認コマンド:

```bash
# Issueの場合（最新のコメントだけ）
gh issue view {number} --repo {owner/repo} --json comments --jq '.comments[-1]'

# PRの場合（最新のコメントだけ）
gh pr view {number} --repo {owner/repo} --json comments --jq '.comments[-1]'
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

## permalinkの生成方法

```bash
# コミットハッシュを取得
git log -1 --format='%H' -- {file_path}

# リモートURLからowner/repoを取得
git remote get-url origin | sed 's|.*github.com[:/]||' | sed 's|\.git$||'
```

## コメント追加方法

### 確認モード（引数で切り替え）

* デフォルト（確認なし）: まとめをファイルに書き出し、パスを提示して即座に投稿する
* `--confirm` 指定時（確認あり）: ファイルに書き出し、パスを提示したあと、ユーザーの承認を得てから投稿する

引数の判定は `args` に `--confirm` が含まれているかで行う。

### 本文のファイル出力（必須・確認の有無に関わらない）

コメント本文は必ず一時ファイルに書き出す。エスケープの罠（バックティック・`$` 展開）を構造的に回避するため、`gh` にはファイル経由（`-F`）で渡す。HEREDOCは使わない。

```bash
# ファイルパスは投稿先に応じて命名（上書き前提・投稿後も残す）
body_file="/tmp/log-ai-conversation-${type}-${number}.md"  # type: issue | pr
```

本文の書き出しは Write ツールで行う。

### ファイルパスの提示（必須・確認の有無に関わらない）

書き出した本文ファイルのパスをチャットに提示する。Neovimで開いて内容を確認・修正できるようにするため:

```
コメント本文: /tmp/log-ai-conversation-issue-123.md
```

Neovimで開く場合（ユーザー側の操作）:

```vim
:e /tmp/log-ai-conversation-issue-123.md
```

### 投稿の実行

確認モードに応じて実行タイミングを切り替える:

* デフォルト: ファイル書き出し・パス提示後、即座に実行
* `--confirm`: ユーザーに「このコメントを{Issue/PR} #{number} に追加してよいですか？」と確認し、承認した場合のみ実行

```bash
# Issueの場合
gh issue comment {number} --repo {owner/repo} -F "${body_file}"

# PRの場合
gh pr comment {number} --repo {owner/repo} -F "${body_file}"
```

投稿後は投稿先URLとファイルパスを併せて提示する（あとから Neovim で本文を確認できるよう、ファイルは残す）。

## 出力例

以下はlazygitのworktree操作についてAIと会話した内容をまとめた例です。

````markdown
### lazygitでworktree viewが表示されない

lazygitでworktree viewが表示されない問題を調査した。

設定ファイルを確認したところ、`]`/`[`でタブ移動してWorktreesタブへアクセスできることがわかった。
また、設定ファイルにtypoがあることも発見した。

```yaml
screenMode: "normal"  # "nomarl" から修正
```
https://github.com/happy663/dotfiles/blob/xxx/conf/.config/lazygit/config.yml#L6

参考:
- https://raw.githubusercontent.com/jesseduffield/lazygit/master/docs/keybindings/Keybindings_ja.md


### lazygit終了後にworktreeのディレクトリが反映されない

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


### worktreeとbranchの違いがわからなかった

「同じmainを複数worktreeで同時checkoutできない」の意味が最初わからなかった。

何度か質問して理解した内容:
- worktreeは「作業ディレクトリ」を増やすもの
- branchは「履歴の線」で、worktreeごとに1つチェックアウトする
- 同じブランチ名を複数worktreeで同時に使うことはGitが禁止している

つまり:
- OK: ~/dotfiles = main, ~/dotfiles-wt = feat/x
- OK: ~/dotfiles = main, ~/dotfiles-wt = detached(mainのコミット)
- NG: ~/dotfiles = main, ~/dotfiles-wt = main
````
