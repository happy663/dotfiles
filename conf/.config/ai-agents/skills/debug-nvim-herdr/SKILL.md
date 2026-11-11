---
name: debug-nvim-herdr
description: |
  隔離した herdr の名前付きセッションで実際の Neovim を起動し、herdr の CLI（pane send-text / send-keys / read）で
  操作・観察してデバッグする。herdr まわりの設定（agent_term/outer の herdr 送り先、herdr-nvim-nav、
  smart-splits の herdr 連携、herdr の config.toml やプラグイン）の動作確認、herdr の中での nvim の起動確認、
  「herdr でデバッグして」「herdr の中で動くか確かめて」などのリクエストで使用する。
  herdr と関係ない nvim のデバッグは debug-nvim-tmux を使う。
---

# Debug Neovim via herdr

## Why（直接実行しない理由と、隔離する理由）

- Agent のシェルはユーザーの Neovim のターミナルの中で動いていることが多い。`$NVIM` に親 Neovim のソケットが入り、zsh では `nvim` が `nvr` のエイリアスになる（`conf/.config/zsh/environment.zsh`）。そのまま nvim を起動すると、親 Neovim に split を開いてしまう（2026-11-11 に実際に起きた）
- ユーザーが普段使っている herdr のセッション（default）には触れない。名前付きセッション（`herdr --session <name>`）で別のサーバーを立てる。ソケットは `~/.config/herdr/sessions/<name>/herdr.sock` になる
- `XDG_CONFIG_HOME` は変えない。変えると nvim がユーザーの設定を読まなくなる

この隔離は `scripts/hd.sh` がまとめて行う（NVIM・TMUX・REX_*・HERDR_* を外して画面なしのサーバーを起動する）。

## Basic flow

スクリプトのパスとセッション名を決める。セッション名は英数字・`-`・`_` だけ。

```bash
hd=~/.config/ai-agents/skills/debug-nvim-herdr/scripts/hd.sh
s=nvim-debug
```

```bash
# 1. 隔離 herdr を起動し、作業ディレクトリでワークスペースを作る
"$hd" start "$s" /path/to/workdir

# 2. 素の nvim を起動（起動完了は nvim が書く ready ファイルで待つ）
"$hd" nvim "$s"            # ファイルを開くなら: "$hd" nvim "$s" path/to/file

# 3. 画面を見る
"$hd" read "$s"

# 4. 操作する（Ex コマンドは ex、それ以外は keys / text）
"$hd" ex "$s" 'messages'
sleep 1
"$hd" read "$s" | tail -20

# 5. 片付け（nvim を閉じ、セッションを止めて削除する）
"$hd" stop "$s"
```

- 同じ名前のセッションが残っていると `start` が止まる。前回のものなら `"$hd" stop "$s"`、別の作業中なら別名にする
- `herdr` が PATH になければ、`nix build --inputs-from <dotfiles> nixpkgs#herdr` で取ってくる（hd.sh が自動で行う）
- 「送る → 待つ → 読む」は 1 回の Bash 呼び出しにまとめる

### ユーザーに画面を見てもらう

`"$hd" attach-cmd "$s"` が表示するコマンド（`herdr session attach <name>`）を、ユーザーに別のターミナル（Ghostty など）で実行してもらう。herdr の中からは入れ子になるので実行できない。抜けるときは herdr の detach（prefix のあと q）。attach するとペインの大きさがその端末に合わせて変わる。

## 出力の取り出し方

画面の読み取りは「今どういう状態か」の確認用。エラー・メッセージ・checkhealth などの正確な出力は、nvim にファイルへ書かせて読む。末尾に `__DONE__` を書かせ、それを待つ。

```bash
out=/tmp/herdr-debug/$s/messages.txt
: > "$out"
"$hd" ex "$s" "lua local l = vim.split(vim.fn.execute('messages'), '\n'); table.insert(l, '__DONE__'); vim.fn.writefile(l, '$out')"
for i in $(seq 1 20); do grep -q __DONE__ "$out" && break; sleep 0.5; done
cat "$out"
```

長い Lua は Ex コマンドで送らず、一時ファイルに書いて `"$hd" ex "$s" "luafile /tmp/herdr-debug/$s/probe.lua"` で実行する。Noice の通知履歴、checkhealth、visual 操作の調べ方、定番の確認項目は debug-nvim-tmux の SKILL.md と同じ（`tmux send-keys` を `hd.sh ex` / `hd.sh keys` に読み替える）。

## herdr 側の状態を見る

herdr まわりの確認では、herdr の CLI でこのセッションの状態を見る。

```bash
"$hd" herdr "$s" agent list                      # エージェント一覧と状態（agent_term/outer の確認）
"$hd" herdr "$s" agent explain w1:p1             # 検出の内訳
"$hd" herdr "$s" pane list                       # ペイン一覧
"$hd" herdr "$s" pane layout --pane w1:p1        # ペインの大きさ
"$hd" herdr "$s" pane split w1:p1 --direction right --no-focus   # ペインを増やす
```

ペイン ID は start が表示する（通常は `w1:p1`）。nvim の中では `HERDR_ENV=1` と `HERDR_PANE_ID` が入っているので、herdr の中で動く処理（OSC 7501 の送り先など）をそのまま試せる。

## 注意点

- 画面なしで起動したサーバーのペインは 120x40。サイズに依存する確認は、ユーザーに attach してもらうか、レイアウトを見てから判断する
- シェルの起動直後に送ったキーは届かないことがある（start は 2 秒待つ）。届いていなければ `read` で確認してから送り直す
- `herdr pane report-agent` の source に `herdr:claude` などは使えない（herdr の公式連携用に予約されていて、状態が反映されない）
- 作業が終わったら必ず `stop` する。残すと `herdr session list` にセッションが残り続ける
