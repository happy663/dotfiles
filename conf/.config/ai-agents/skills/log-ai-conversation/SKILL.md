---
name: log-ai-conversation
description: AIとの会話をまとめてGitHub issueにコメントとして追加する。手動で呼び出して使用。
allowed-tools: Bash, Read, mcp__acp__Read, WebFetch
disable-model-invocation: false
---

# AIとの会話をissueにログする

現在の会話をまとめて、GitHub issueにコメントとして追加します。

## 対象の会話

* 前回このskillを呼び出した以降の会話を対象にする
* 初回呼び出しの場合は全会話を対象にする

## 出力先の特定

1. Octoバッファ（`octo://`で始まるバッファ）が開いている場合
   * ユーザーにissue番号を確認する
2. Octoバッファがない場合
   * ユーザーにリポジトリとissue番号を確認する

## まとめ方

* 作業ログ形式（時系列・試行錯誤・主観表現OK）
* トピックごとに `### {トピック}` で見出しをつける
* 1コメント = 1まとまり
* 「問題→調査→試行→結果」の流れを意識する
* 直前のissueコメントを `gh issue view {number} --repo {owner/repo} --comments` で確認し、前のコメントと内容が重複しないよう・話の流れが自然につながるよう意識する

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

### 確認ステップ（必須）

`gh issue comment` を実行する前に、必ずユーザーに確認を取ること。

1. 追加予定のコメント全文をチャットに表示する
2. 「このコメントをissue #{number} に追加してよいですか？」と確認する
3. ユーザーが明示的に承認した場合のみコマンドを実行する

```bash
gh issue comment {number} --repo {owner/repo} --body "..."
```

HEREDOCを使用してコメント本文を渡す:

```bash
gh issue comment {number} --repo {owner/repo} --body "$(cat <<'EOF'
## トピック名

内容...
EOF
)"
```

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
