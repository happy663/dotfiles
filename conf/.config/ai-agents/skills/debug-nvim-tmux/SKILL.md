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

tmuxセッションは親Neovimの外側に独立したTTYを作れる。さらに `env NVIM= command nvim` で起動すれば、親NeovimのRPCソケットや `nvim` alias / wrapper の影響を避けて、素のNeovimをフル起動できる。ユーザーが画面を見たい場合に備え、標準ではデタッチせず、ユーザーがそのまま見えるセッションとして扱う。

## Basic flow

```bash
# 1. セッション名を決める（既存セッションがあれば必ず別名にする。
#    既にNeovimが開いているtmuxへsend-keysすると、コマンド文字列がバッファに入力される）
session=nvim-debug
if tmux has-session -t "$session" 2>/dev/null; then
  session="nvim-debug-$(date +%s)"
fi

ready="/tmp/${session}-ready"
rm -f "$ready"

# 2. ユーザーが見える形でセッションを起動する（ここでtmuxに入る）
tmux new-session -s "$session" -c /path/to/workdir \
  "env NVIM= command nvim +'lua vim.fn.writefile({\"ready\"}, \"$ready\")'"
```

上の `tmux new-session` はデタッチしないため、そのシェルはtmux表示に入る。以降の確認・操作は、Agentの別シェルから同じ `session` 名を指定して実行する。

```bash
# 3. nvim起動待ち（画面captureではなく、Neovim側が書いたreadyファイルを待つ）
for i in $(seq 1 16); do
  test -f "$ready" && break
  sleep 1
done

# 4. 画面確認
tmux capture-pane -t "$session" -p -S -50 | grep -v '^$'

# 5. コマンド送信（実行後1-2秒待ってからcapture）
tmux send-keys -t "$session" ':messages' Enter
sleep 2
tmux capture-pane -t "$session" -p | grep -v '^$' | tail -20

# 6. 終了と片付け
tmux send-keys -t "$session" ':qa!' Enter
tmux kill-session -t "$session"
```

Agentが同じセッションを操作する場合は、別のシェルから `tmux send-keys` / `tmux capture-pane` を使う。ユーザーには実際のセッション名を共有する。すでに別端末から見る必要がある場合だけ、`tmux attach -t "$session"` で同じ画面に入ってもらう。

運用の原則:

* ユーザーが見たいデバッグでは `tmux new-session -d` を使わない。最初から attached セッションを作る
* Agent側の作業継続を優先してデタッチ起動する必要がある場合は、事前にユーザーへ理由を伝え、実際の `tmux attach -t "$session"` コマンドも同時に案内する
* 「send-keys → sleep → capture」の連続操作は1つのBash呼び出しにまとめる。ツール呼び出しごとの往復オーバーヘッドが減り、手順の抜けも防げる
* 正確な出力が必要なもの（エラー・スタックトレース・checkhealth等）は画面captureではなく次節のファイル経由で取る。captureは「今どういう画面状態か」の確認用と割り切る
* tmux内で起動するときも `env NVIM= command nvim` を使う。tmux serverの環境やaliasの影響を避け、親Neovimへリモート接続しないことを明示する

## Extracting output via files（画面captureより正確・低ノイズ）

`:messages` やLua評価の結果を capture-pane で読むと、noiceのポップアップで途切れたり、ウィンドウ枠・バッファ内容などのノイズが大量に混ざる。Neovim側からファイルに書き出させると、1回で完全な生データが取れて、読む側のコンテキスト消費も小さい。

```bash
out="/tmp/nvim-debug-messages.txt"
rm -f "$out"

# :messages の全文（スタックトレース含む）を取る
tmux send-keys -t "$session" ':lua vim.fn.writefile(vim.split(vim.fn.execute("messages"), "\n"), "'"$out"'")' Enter
for i in $(seq 1 10); do
  test -f "$out" && break
  sleep 1
done
cat "$out"
```

```bash
out="/tmp/nvim-debug-health.txt"
rm -f "$out"

# checkhealth のような長いバッファはバッファ内容ごと落とす
# （G/zt でスクロールしながら複数回captureするより速くて確実）
tmux send-keys -t "$session" ':checkhealth vim.deprecated' Enter
sleep 5
tmux send-keys -t "$session" ':lua vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), "'"$out"'")' Enter
for i in $(seq 1 10); do
  test -f "$out" && break
  sleep 1
done
cat "$out"
```

複雑なプローブ（バッファ一覧の調査、プラグイン内部状態の確認など）は、長い `:lua` ワンライナーを send-keys しない。引用符の罠と誤爆リスクがあるため、一時Luaファイルを用意して `:luafile` で実行し、結果もファイルに書かせる。リポジトリ内のファイル作成・編集には heredoc ではなく通常の編集手順を使う。一時ファイルだけに限定する。

```bash
probe="/tmp/nvim-debug-probe.lua"
out="/tmp/nvim-debug-probe-out.txt"
rm -f "$out"

cat > "$probe" <<'EOF'
local out = {}
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(b) then
    table.insert(out, b .. " mod=" .. tostring(vim.bo[b].modified) .. " " .. vim.api.nvim_buf_get_name(b))
  end
end
vim.fn.writefile(out, "/tmp/nvim-debug-probe-out.txt")
EOF
tmux send-keys -t "$session" ':luafile '"$probe" Enter
for i in $(seq 1 10); do
  test -f "$out" && break
  sleep 1
done
cat "$out"
```

出力ファイルの存在自体がセンチネルになるので、時間のかかる処理は固定sleepの代わりに「ファイルができるまでポーリング」で待てる。

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
* 出力が長い場合は `vim.fn.execute("history :")` 等を「Extracting output via files」の方式でファイルに落として読む。

## Pitfalls (実際に踏んだ罠)

* send-keys の後は必ず待ちを挟む。sleepなしのcaptureは古い画面を拾う。起動はBasic flowのreadyファイルで待ち、通常のコマンドは1-2秒。時間が読めない処理は出力ファイルの存在をポーリングする
* ダッシュボード（スタート画面）表示中は単キー入力がショートカットに食われる。操作は必ず `:` コマンドで行う
* `:50` のような行ジャンプは `send-keys ':50'` と `send-keys Enter` を分けて送ると安定する
* 長いバッファ（checkhealth等）は画面に入りきらない。スクロールしながら複数回captureするのではなく、「Extracting output via files」のバッファ書き出しで一括取得する
* エラーメッセージをcaptureで読むとnoiceのポップアップ等で途切れる。正確な全文が必要なら必ずファイル経由で取る
* capture結果は `grep -v '^$'` で空行を落とすと読みやすい。全体が必要なら `-S -50` で履歴も含める
* `capture-pane` が空を返したら、直前のsend-keysが反映される前に読んでいる。sleepを増やして再取得する
* 同名セッションが残っているときは再利用しない。既存のNeovim画面へsend-keysしてバッファを汚す可能性があるため、必ず別名セッションを作る

## Safety rules

* Agentのシェルで nvim / nvr を直接実行しない（headless含む）。必ずtmuxセッション内で起動する
* `:Lazy update` や `:Lazy sync` など状態を変える操作は、ユーザーの明示的な指示がある場合のみ実行する
* デバッグ完了後はセッションを kill する。ユーザーと共同作業中のセッションは残し、ユーザーに判断を委ねる
