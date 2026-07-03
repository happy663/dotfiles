---
name: debug-nvim-tmux
description: |
  tmuxセッション内で実際のNeovimを起動し、send-keys / capture-pane で操作・観察してデバッグする。
  Neovimの起動確認、プラグインエラーの調査、checkhealthの確認、設定変更の動作確認、
  「nvimをデバッグして」「起動確認して」「checkhealth見て」などのリクエストで使用する。
  Agentがnvimを直接実行する必要が生じた場合も、必ずこのスキルの手順を使うこと。
---

# Debug Neovim via tmux

## Why tmux (絶対に直接実行しない理由)

このAgentのシェルは、ユーザーが操作中のNeovimのターミナルバッファ内で動いている。

* `$NVIM` に親NeovimのRPCソケットが設定されている
* `nvim` は `nvr`（neovim-remote）にエイリアスされており、実行すると新規起動ではなく親Neovimへのリモート操作になる
* このため `nvim --headless` を含め、Agentのシェルから nvim を直接実行すると、ユーザーの生きているセッションに干渉して落とした実績がある

tmuxセッションは親Neovimの外側にあるため `$NVIM` が未設定で、エイリアスも効かず、素のnvimバイナリが独立したTTYでフル起動する。ユーザーも `tmux attach` で同じ画面を見られるので、共同デバッグにも使える。

## Basic flow

```bash
# 1. セッション作成（名前は nvim-debug 固定。衝突したら nvim-debug-2 等にずらす）
tmux new-session -d -s nvim-debug -c /path/to/workdir

# 2. nvim起動（起動完了まで8秒以上待つ）
tmux send-keys -t nvim-debug 'nvim' Enter
sleep 8

# 3. 画面確認
tmux capture-pane -t nvim-debug -p -S -50 | grep -v '^$'

# 4. コマンド送信（実行後1-2秒待ってからcapture）
tmux send-keys -t nvim-debug ':messages' Enter
sleep 2
tmux capture-pane -t nvim-debug -p | grep -v '^$' | tail -20

# 5. 終了と片付け
tmux send-keys -t nvim-debug ':qa!' Enter
tmux kill-session -t nvim-debug
```

ユーザーに共有する場合は `tmux attach -t nvim-debug` を案内する。

## Standard checks

デバッグ時の定番確認コマンド。上から順に実施する。

1. 起動直後の画面: エラー表示・起動時間・プラグインロード数を確認する
2. `:messages` — 起動時のエラー・警告を確認する。何も表示されなければメッセージなし
3. `:checkhealth vim.deprecated` — 非推奨API警告の呼び出し元（自分の設定かプラグインか）をスタックトレースで特定する
4. 実ファイルを開く（`:e <file>`）— treesitterハイライト、LSPアタッチ（ステータスラインの診断カウント）を確認する
5. `:checkhealth <対象>` — 特定プラグインの詳細診断
6. `:Lazy` — プラグインの状態確認（更新は指示がない限り行わない）

## Recovering user actions（直前の操作の復元）

ユーザーから「Xしたらエラー」と報告を受けたが、具体的な手順が分からない時。
Neovim 自体が記録している情報から直前の操作を復元する。自分の勘で再現手順を
決め打ちせず、まずこれらを取ってから再現を組み立てる。

1. `:ls` — 現在開いているバッファ一覧（何のファイルを開いていたか）
2. `:history :` — コマンド履歴（`:Lua` `:Obsidian` 等、何を打ったか）
3. `:oldfiles` — 最近開いたファイル（MRU、セッション起動後に何を開いたか）
4. `:ju` — jumplist（タグ/定義ジャンプ等の移動足跡）
5. `:messages` — エラー・警告

これらを時系列で突き合わせると「バッファAを開く → コマンドBを実行 → エラー」
のような再現手順が復元できる。

注意:
* キーマップ経由のプラグイン起動（`<leader>tf` 等）は `:history` に載らない。
  トレースログ実装で補完予定。
* 出力が長い場合は `G` で末尾へ飛んで最新分を読む。

## Pitfalls (実際に踏んだ罠)

* send-keys の後は必ず sleep を挟む。起動は8秒以上、通常のコマンドは1-2秒。sleepなしのcaptureは古い画面を拾う
* ダッシュボード（スタート画面）表示中は単キー入力がショートカットに食われる。操作は必ず `:` コマンドで行う
* `:50` のような行ジャンプは `send-keys ':50'` と `send-keys Enter` を分けて送ると安定する
* 長いバッファ（checkhealth等）は画面に入りきらない。`G`（末尾）、`zt`（カーソル行を上端へ）、行番号ジャンプでスクロールしながら複数回captureする
* capture結果は `grep -v '^$'` で空行を落とすと読みやすい。全体が必要なら `-S -50` で履歴も含める
* `capture-pane` が空を返したら、直前のsend-keysが反映される前に読んでいる。sleepを増やして再取得する
* 同名セッションが残っていると new-session が失敗する。開始前に `tmux has-session -t nvim-debug` で確認する

## Safety rules

* Agentのシェルで nvim / nvr を直接実行しない（headless含む）。必ずtmuxセッション内で起動する
* `:Lazy update` や `:Lazy sync` など状態を変える操作は、ユーザーの明示的な指示がある場合のみ実行する
* デバッグ完了後はセッションを kill する。ユーザーと共同作業中のセッションは残し、ユーザーに判断を委ねる
