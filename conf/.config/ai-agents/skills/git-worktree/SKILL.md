---
name: git-worktree
description: git worktreeを切って、別ディレクトリで作業を開始するための手順。新しいタスクを既存の作業ツリーから分離して進めたい場合に使用する。
argument-hint: "[タスク名またはブランチ名]"
allowed-tools: Bash
disable-model-invocation: false
---

# git worktree 作成スキル

新しい作業を既存の作業ツリーから分離して始めるために、専用のbranchとworktreeを作成します。
このスキルはworktree作成手順だけを担当します。実装・検証・削除までの運用は通常のタスク手順に従います。

## 標準フロー

### 1. 現在の状態を確認

既存の変更を巻き込まないように、まず作業ツリーと現在branchを確認します。

```bash
git status --short
git branch --show-current
git rev-parse --show-toplevel
```

未コミット変更がある場合も、勝手にstash・commit・revertしないでください。
worktree作成に支障がある場合だけユーザーに確認します。

### 2. 名前を決める

引数またはユーザーの依頼内容からタスク名を決め、slug化します。

標準の命名規則:

- branch: `wt/<slug>`
- worktree path: `../<repo-name>-wt/<slug>`

例:

```bash
TASK="add-git-worktree-skill"
SLUG=$(printf "%s" "$TASK" | tr '[:upper:]' '[:lower:]' | sed -E 's@[[:space:]/]+@-@g; s@[^a-z0-9._-]@@g; s@-+@-@g; s@^-+@@; s@-+$@@')
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
BASE_BRANCH=$(git branch --show-current)
BRANCH="wt/$SLUG"
WT_PATH="../${REPO_NAME}-wt/$SLUG"
```

`SLUG` が空になる場合は作成を止め、タスク名をユーザーに確認します。

### 3. 衝突を確認

既存branchまたは既存pathを上書きしないでください。

```bash
git show-ref --verify --quiet "refs/heads/$BRANCH"
test -e "$WT_PATH"
```

どちらかが存在する場合は、別名にするか既存worktreeを使うかをユーザーに確認します。

### 4. worktreeを作成

```bash
git worktree add -b "$BRANCH" "$WT_PATH" "$BASE_BRANCH"
```

作成後、必ず作成先へ移動して以降の作業を進めます。

```bash
cd "$WT_PATH"
```

### 5. 作成結果を報告

作成後は、以下を簡潔に報告します。

- base branch
- created branch
- worktree path

作業後もworktreeは残します。ユーザーから明示依頼がない限り、`git worktree remove` は実行しません。

## lazygit補足

このリポジトリのlazygit設定には、localBranches上で `N` を押すとbranchとworktreeを作成するcustomCommandがあります。
Codexが作業する場合はCLIの `git worktree add` を標準とし、lazygit操作はユーザーが手動で作成する場合の補助として扱います。

## 注意事項

- 既存のユーザー変更をstash・commit・revertしない
- 既存branchや既存pathを上書きしない
- worktree作成後は作成先のディレクトリで作業する
- 完了報告ではworktreeを残していることを明記する
