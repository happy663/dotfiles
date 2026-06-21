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

## なぜ使うか

通常のシェル実行は、長時間タスクでは会話の待ち時間、コンテキスト消費、途中入力、ログ喪失が問題になりやすいです。
tmuxに預けると、タスクを外部状態として保持し、Agentは必要なタイミングだけ状態確認やログ回収ができます。
これにより、Agentが実行完了を同期的に待ち続けずに済み、中断に強くなり、sudo待ちや失敗箇所を後から確認しやすくなります。
ただし、tmux自体がトークン消費を減らすわけではありません。頻繁な監視や大きなログ回収は、通常実行よりもトークン消費を増やすことがあります。

## 使う場面

- 30秒以上かかりそうなビルド、テスト、lint、Nix評価
- dev server、watcher、ログ監視など継続実行するコマンド
- 複数の検証を並列に走らせたい場合
- 対話的CLIや途中確認が必要になりそうなコマンド

短い確認コマンド、単発のファイル読み取り、すぐ終わる検索では通常のBash実行を優先します。

## 実行時間の計測

実行時間を分析したい場合は、tmuxに預けるコマンド自体を `/usr/bin/time -p` で包みます。

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh start apply-nix -- /usr/bin/time -p make apply-nix
```

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

監視は原則30-60秒間隔にします。
通常確認は `list` を優先し、ログ取得は状態変化、失敗、sudo待ち、長時間無出力の確認時だけ行います。
これは、tmux監視による追加のトークン消費を増やしすぎないためです。

### 3. ログ回収

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh show test
```

直近行数を指定する場合:

```bash
conf/.config/ai-agents/skills/ai-tmux/scripts/ai-tmux.sh show test -n 40
```

大量ログが予想される場合は `show` を繰り返さず、ログファイルに対して `rg` で重要語だけ確認します。
必要な行だけを抽出し、ユーザーには要点を短く報告します。

```bash
rg 'error|failed|sudo|finished_at|exit_code' "${XDG_STATE_HOME:-$HOME/.local/state}/ai-tmux/logs/test.log"
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
- `ps` で進行状況を見る場合は全件出力を避け、対象プロセス名に絞ってください。
- ユーザーへの途中報告は、起動、入力待ち、フェーズ遷移、失敗、完了など状態変化があった時を中心にしてください。
