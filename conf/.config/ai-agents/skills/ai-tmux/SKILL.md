---
name: ai-tmux
description: Agentの作業を止めずに済む場面でtmuxを活用する。判断軸は「このコマンドの完了を同期的に待つとAgentの作業が止まるか」。止まらない（数秒で終わる確認コマンド）ならBash直接。止まるが管理不要（所要時間が不確実、一度きりの非同期実行）ならtmux直接利用（tmux new-session -d）。止まる上に管理も必要（長時間ビルド・テスト・dev server・watcher・並列検証・対話的CLI・ログ永続化）ならこのスキルを呼び出してジョブ管理する。
argument-hint: "[start|list|show|attach|stop|close] ..."
allowed-tools: Bash
disable-model-invocation: false
---

# ai-tmux

AI Agent用のtmuxジョブ管理スキルです。
人間が常用するCLIではなく、Agentが長時間・継続・並列タスクを外部状態として保持するために使います。

## 判断基準: Bash / tmux直接 / ai-tmux

コマンドを実行する前に、以下の基準で実行方法を選択する。

### Bash直接（デフォルト）

* 数秒で終わる確認コマンド（git status, rg, ls, cat）
* 結果が確実にすぐ返るもの
* 単発のファイル読み取り・検索

### tmux直接（軽量モード）

* 所要時間が不確実だが、ジョブ管理は不要なもの（例: 外部プロセス起動、APIコール）
* 一度きりの非同期実行で、ログ永続化やジョブ一覧管理が要らないもの
* 完了確認だけできれば十分なもの

### ai-tmux（フルモード）

* 30秒以上かかることが明らかなビルド、テスト、lint、Nix評価
* dev server、watcher、ログ監視など継続実行するコマンド
* 複数の検証を並列に走らせ、ジョブ一覧で管理したい場合
* 対話的CLIや途中確認が必要になりそうなコマンド
* ログを永続化して後から分析したい場合

## tmux直接利用パターン

ai-tmuxのジョブ管理が不要な場合は、tmuxを直接使う。

### 起動と結果回収

```bash
tmux new-session -d -s tmp-task -c "$PWD" 'bash -lc "command > /tmp/result.txt 2>&1"'
```

### 完了待ち（Bash run_in_background と組み合わせ）

```bash
until ! tmux has-session -t tmp-task 2>/dev/null || [ -s /tmp/result.txt ]; do sleep 3; done
```

### 出力確認（セッションがまだ生きている場合）

```bash
tmux capture-pane -t tmp-task -p -S -30
```

### 片付け

```bash
tmux kill-session -t tmp-task 2>/dev/null
```

## なぜ使うか

通常のシェル実行は、長時間タスクでは会話の待ち時間、コンテキスト消費、途中入力、ログ喪失が問題になりやすいです。
tmuxに預けると、タスクを外部状態として保持し、Agentは必要なタイミングだけ状態確認やログ回収ができます。
これにより、Agentが実行完了を同期的に待ち続けずに済み、中断に強くなり、sudo待ちや失敗箇所を後から確認しやすくなります。
ただし、tmux自体がトークン消費を減らすわけではありません。頻繁な監視や大きなログ回収は、通常実行よりもトークン消費を増やすことがあります。

## 実行時間の計測

実行時間を分析したい場合は、tmuxに預けるコマンド自体を `/usr/bin/time -p` で包みます。

```bash
scripts/ai-tmux.sh start apply-nix -- /usr/bin/time -p make apply-nix
```

## コマンド

スクリプトパス:

```bash
scripts/ai-tmux.sh
```

基本形:

```bash
scripts/ai-tmux.sh start <name> -- <command...>
scripts/ai-tmux.sh list
scripts/ai-tmux.sh show <name>
scripts/ai-tmux.sh attach <name>
scripts/ai-tmux.sh stop <name>
scripts/ai-tmux.sh close <name>
```

## 標準フロー

### 1. 起動

```bash
scripts/ai-tmux.sh start test -- bash -lc 'cargo test'
```

ジョブ名は `A-Za-z0-9_.-` のみ使用します。
tmux session名は `ai-<name>` になります。

### 2. 状態確認

```bash
scripts/ai-tmux.sh list
```

監視は原則30-60秒間隔にします。
通常確認は `list` を優先し、ログ取得は状態変化、失敗、sudo待ち、長時間無出力の確認時だけ行います。
これは、tmux監視による追加のトークン消費を増やしすぎないためです。

### 3. ログ回収

```bash
scripts/ai-tmux.sh show test
```

直近行数を指定する場合:

```bash
scripts/ai-tmux.sh show test -n 40
```

大量ログが予想される場合は `show` を繰り返さず、ログファイルに対して `rg` で重要語だけ確認します。
必要な行だけを抽出し、ユーザーには要点を短く報告します。

```bash
rg 'error|failed|sudo|finished_at|exit_code' "${XDG_STATE_HOME:-$HOME/.local/state}/ai-tmux/logs/test.log"
```

### 4. 必要なら入る

```bash
scripts/ai-tmux.sh attach test
```

### 5. 不要になったら閉じる

```bash
scripts/ai-tmux.sh close test
```

`close` はtmux sessionだけを閉じ、ログとメタ情報は残します。

## 注意

* 同じジョブ名のsessionが存在する場合、`start` は失敗します。
* 完了後もsessionは残ります。結果を確認して不要なら `close` してください。
* `stop` は実行中paneに `C-c` を送ります。session自体は残します。
* ログは `${XDG_STATE_HOME:-$HOME/.local/state}/ai-tmux/logs/` に保存されます。
* `ps` で進行状況を見る場合は全件出力を避け、対象プロセス名に絞ってください。
* ユーザーへの途中報告は、起動、入力待ち、フェーズ遷移、失敗、完了など状態変化があった時を中心にしてください。
