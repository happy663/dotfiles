---
name: ai-tmux
description: AI Agentが長時間タスク、watcher、並列検証、対話的CLIをtmuxに預け、あとで状態確認・ログ回収するために使用する。
argument-hint: "[start|list|show|attach|stop|close] ..."
allowed-tools: Bash
disable-model-invocation: false
---

# ai-tmux

AI Agent用のtmuxジョブ管理スキルです。
人間が常用するCLIではなく、Agentが長時間・継続・並列タスクを外部状態として保持するために使います。

## 使う場面

- 30秒以上かかりそうなビルド、テスト、lint、Nix評価
- dev server、watcher、ログ監視など継続実行するコマンド
- 複数の検証を並列に走らせたい場合
- 対話的CLIや途中確認が必要になりそうなコマンド

短い確認コマンド、単発のファイル読み取り、すぐ終わる検索では通常のBash実行を優先します。

## コマンド

スクリプトパス:

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh
```

基本形:

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh start <name> -- <command...>
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh list
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh show <name>
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh attach <name>
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh stop <name>
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh close <name>
```

## 標準フロー

### 1. 起動

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh start test -- bash -lc 'cargo test'
```

ジョブ名は `A-Za-z0-9_.-` のみ使用します。
tmux session名は `ai-<name>` になります。

### 2. 状態確認

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh list
```

### 3. ログ回収

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh show test
```

直近行数を指定する場合:

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh show test -n 200
```

### 4. 必要なら入る

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh attach test
```

### 5. 不要になったら閉じる

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh close test
```

`close` はtmux sessionだけを閉じ、ログとメタ情報は残します。

## 注意

- 同じジョブ名のsessionが存在する場合、`start` は失敗します。
- 完了後もsessionは残ります。結果を確認して不要なら `close` してください。
- `stop` は実行中paneに `C-c` を送ります。session自体は残します。
- ログは `${XDG_STATE_HOME:-$HOME/.local/state}/ai-tmux/logs/` に保存されます。
