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
# rmは許可されていないため、事前に空にしてから「内容が空でないか」で完了を待つ
: > "$ready" 2>/dev/null || true

# 2. ユーザーが見える形でセッションを起動する（ここでtmuxに入る）
tmux new-session -s "$session" -c /path/to/workdir \
  "env NVIM= command nvim +'lua vim.fn.writefile({\"ready\"}, \"$ready\")'"
```

上の `tmux new-session` はデタッチしないため、そのシェルはtmux表示に入る。以降の確認・操作は、Agentの別シェルから同じ `session` 名を指定して実行する。

```bash
# 3. nvim起動待ち（画面captureではなく、Neovim側が書いたreadyファイルを待つ）
#    rmを使わず、ファイルが「空でない（=Neovimが書いた）」ことで完了とする
for i in $(seq 1 16); do
  [ -s "$ready" ] && break
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
: > "$out" 2>/dev/null || true

# :messages の全文（スタックトレース含む）を取る
# 末尾に __DONE__ マーカーを必ず書く。メッセージが空でもファイルは非空になり、
# 待ちループが「空＝未完了」と誤判定しない
tmux send-keys -t "$session" ':lua local l = vim.split(vim.fn.execute("messages"), "\n"); table.insert(l, "__DONE__"); vim.fn.writefile(l, "'"$out"'")' Enter
for i in $(seq 1 10); do
  grep -q '__DONE__' "$out" 2>/dev/null && break
  sleep 1
done
cat "$out"
```

Noice / nvim-notify を使っている環境では、`vim.notify()` の警告やエラーが `:messages` に
残らず、Noice の通知履歴にだけ残ることがある。画面に通知が出た、または `FileType notify`
/ `FileType noice` が見えるのに `:messages` が空の場合は、Noice の履歴も確認する。

```bash
out="/tmp/nvim-debug-noice-notify.txt"
: > "$out" 2>/dev/null || true

tmux send-keys -t "$session" ':lua local ok, manager = pcall(require, "noice.message.manager"); local out = {}; if ok then for _, msg in ipairs(manager.get({ event = "notify" }, { history = true, sort = true })) do table.insert(out, string.format("[%s] %s", msg.level or msg.kind or "unknown", msg:content())) end else out = { "noice unavailable" } end; table.insert(out, "__DONE__"); vim.fn.writefile(out, "'"$out"'")' Enter
for i in $(seq 1 10); do
  grep -q '__DONE__' "$out" 2>/dev/null && break
  sleep 1
done
cat "$out"
```

```bash
out="/tmp/nvim-debug-health.txt"
: > "$out" 2>/dev/null || true

# checkhealth のような長いバッファはバッファ内容ごと落とす
# （G/zt でスクロールしながら複数回captureするより速くて確実）
tmux send-keys -t "$session" ':checkhealth vim.deprecated' Enter
sleep 5
tmux send-keys -t "$session" ':lua local l = vim.api.nvim_buf_get_lines(0, 0, -1, false); table.insert(l, "__DONE__"); vim.fn.writefile(l, "'"$out"'")' Enter
for i in $(seq 1 10); do
  grep -q '__DONE__' "$out" 2>/dev/null && break
  sleep 1
done
cat "$out"
```

複雑なプローブ（バッファ一覧の調査、プラグイン内部状態の確認など）は、長い `:lua` ワンライナーを send-keys しない。引用符の罠と誤爆リスクがあるため、一時Luaファイルを用意して `:luafile` で実行し、結果もファイルに書かせる。リポジトリ内のファイル作成・編集には heredoc ではなく通常の編集手順を使う。一時ファイルだけに限定する。

```bash
probe="/tmp/nvim-debug-probe.lua"
out="/tmp/nvim-debug-probe-out.txt"
: > "$out" 2>/dev/null || true

cat > "$probe" <<'EOF'
local out = {}
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(b) then
    table.insert(out, b .. " mod=" .. tostring(vim.bo[b].modified) .. " " .. vim.api.nvim_buf_get_name(b))
  end
end
table.insert(out, "__DONE__")
vim.fn.writefile(out, "/tmp/nvim-debug-probe-out.txt")
EOF
tmux send-keys -t "$session" ':luafile '"$probe" Enter
for i in $(seq 1 10); do
  grep -q '__DONE__' "$out" 2>/dev/null && break
  sleep 1
done
cat "$out"
```

出力ファイルの存在自体がセンチネルになるので、時間のかかる処理は固定sleepの代わりに「ファイルができるまでポーリング」で待てる。

## Standard checks

デバッグ時の定番確認コマンド。上から順に実施する。

1. 起動直後の画面: エラー表示・起動時間・プラグインロード数を確認する
2. `:messages` — 起動時のエラー・警告を確認する。何も表示されなければメッセージなし
3. Noice通知履歴 — `vim.notify()` 経由の警告は `:messages` に残らない場合があるため、Noice利用環境では併せて確認する
4. `:checkhealth vim.deprecated` — 非推奨API警告の呼び出し元（自分の設定かプラグインか）をスタックトレースで特定する
5. 実ファイルを開く（`:e <file>`）— treesitterハイライト、LSPアタッチ（ステータスラインの診断カウント）を確認する
6. `:checkhealth <対象>` — 特定プラグインの詳細診断
7. `:Lazy` — プラグインの状態確認（更新は指示がない限り行わない）
8. キーマップ確認 — visual マッピングの発火問題は `maparg()` で定義形式（コマンド文字列 or Lua callback）を確認する。「visual 操作・キーマップのデバッグ」参照

## visual 操作・キーマップのデバッグ

visual マッピングや選択範囲まわりの問題を調べる手順。

### visual モードの判別

`:lua` で呼ばれる関数内では `vim.fn.mode()` が "n" を返す（visual は既に解除済み）。visual モードの判別は `vim.fn.visualmode()` を使う。

* `"v"` = 文字単位選択
* `"V"` = 行単位選択
* `"\22"` = 矩形選択（Ctrl-V）

### 選択範囲の取得と検証

`'<` / `'>` マークは `vim.fn.line(">'")` / `vim.fn.col(">'")` で取得する（1-indexed、バイト単位）。選択範囲が想定どおりかは、ファイルへ書き出して検証する:

```lua
_G.debug_visual = function()
  local out = {}
  out[#out + 1] = "vmode=" .. (vim.fn.visualmode() or "nil")
  out[#out + 1] = "lt=" .. vim.fn.line("'<")
  out[#out + 1] = "gt=" .. vim.fn.line(">'")
  out[#out + 1] = "cur=" .. vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.writefile(out, "/tmp/nvim-debug-vmode.txt")
end
vim.api.nvim_set_keymap("v", "<Space>rc", ":lua _G.debug_visual()<CR>", { noremap = true, silent = true })
```

### マッピング定義の確認

`:vmap <Space>rc` の代わりに、`maparg()` で RHS と callback の有無を確認できる:

```lua
local m = vim.fn.maparg("<Space>rc", "v", false, true)
print(m.rhs)             -- コマンド文字列ベースなら ":lua ..."
print(m.callback ~= nil) -- Lua callback ベースかどうか
```

### この環境の visual マッピングの罠

この環境（dotfiles）では、Lua コールバックベースの visual マッピング（`vim.keymap.set("v", ..., callback)`）が発火しない。`<Space>` が右移動として処理され、後続キーが通常コマンドとして実行される（`r` が置換、`c` が置換文字となり選択文字列が破壊される）。

回避策: `vim.api.nvim_set_keymap("v", "<Space>rc", ":lua _G.func()<CR>")` のコマンド文字列ベースで定義し、関数を `_G` に公開する。

### 受信キーの追跡（vim.on_key）

send-keys の後に想定外の文字（`c>` など）がバッファに入る場合、受信キーを記録して追跡する:

```lua
local f = io.open("/tmp/nvim-debug-keys.txt", "w")
if f then f:write("START\n"); f:close() end
vim.on_key(function(key)
  local f = io.open("/tmp/nvim-debug-keys.txt", "a")
  if f then f:write(vim.fn.keytrans(key) .. "\n"); f:close() end
end)
```

`vim.fn.keytrans()` でキーを可読形式（`<Space>`, `<Esc>`, `<CR>` など）に変換する。コマンドライン入力も記録されるため、マッピングの発火順や予期しないキー送信を特定できる。

## ハイライト調査（文字の色が想定と違う場合）

文字の色が想定と違う（灰色になる、色がつかない、特定ファイルだけ変わる等）場合の調査手順。ハイライトは Neovim で最もレイヤーが多く、最初に罠を知らないと堂々巡りになる。

### 最初に知る: `:Inspect` の限界

`:Inspect`（実体は `vim.inspect_pos`）は syntax / Treesitter / semantic_token / extmark を統合調査する。md 等の Treesitter バッファなら capture 名（`@spell.markdown` 等）まで取れるので、まずはこれを試す。

ただし3つの限界がある:

1. ターミナルバッファでは `No items found at position ...` になる。ターミナルの文字色は `winhighlight + Normal + terminal_color_*` で決まり、`:Inspect` が調べるレイヤー外。ターミナルの色問題は `:Inspect` では絶対に見えない
2. `:Inspect` は capture 名まで。最終的な fg 色（`@spell.markdown` が白か灰か）の解決は自前でやる必要がある（`@グループ` を `nvim_get_hl(0, {name=..., link=true})` で辿る）
3. プログラム的に取るには `vim.inspect_pos(buf, row, col)` が構造体を返すが、色解決は含まれない

### 罠: `screenattr()` / `synID()` は古いレイヤー前提

「画面の実際の描画色を取る」ためにこれらを試すと、新しいレイヤーで無効値が返る:

* `vim.fn.screenattr(line, col)`: ターミナルバッファで `-1`（PTY の ANSI 色は拾えない）
* `vim.fn.synID(line, col, 1)`: Treesitter バッファで `0`（古い `:syntax` 用で、Treesitter を認識しない）

どちらも古い syntax ハイライト（`:syntax`）前提のAPI。ターミナルの ANSI 色や Treesitter の capture は拾えない。実描画色の取得には使えないと心得る。

### 手順A: Treesitter の色を調べる（md 等の通常バッファ）

`vim.treesitter.get_captures_at_pos(buf, row, col)` で capture を取り、対応する `@capture` グループを `nvim_get_hl` で解決する。capture はドット区切り（`spell.markdown`）で、未定義なら親（`@spell`）に fallback することを意識して辿る。`link=true` を付けないとリンク先が取れないので注意。

### 手順B: ターミナルの色を調べる（`:Inspect` が効かない領域）

ターミナルウィンドウの `winhighlight` を直取りし、`Normal:X` の X を `nvim_get_hl` で解決する。

```bash
probe="/tmp/nvim-debug-hl-term.lua"
out="/tmp/nvim-debug-hl-term-out.txt"
: > "$out" 2>/dev/null || true

cat > "$probe" <<'EOF'
local out = {}
local function hl_hex(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
  if ok and hl and hl.fg then return string.format("#%06x", hl.fg) end
  return nil
end
for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
  local b = vim.api.nvim_win_get_buf(w)
  if vim.bo[b].buftype == "terminal" then
    local whl = vim.wo[w].winhighlight or ""
    local norm = whl:match("Normal:([^,]+)")  -- Normal:X の X を抽出
    table.insert(out, string.format("win=%d buf=%d name=%s", w, b, vim.api.nvim_buf_get_name(b)))
    table.insert(out, "  winhl=" .. whl)
    table.insert(out, "  effective Normal fg=" .. tostring(norm and hl_hex(norm) or hl_hex("Normal")) .. " (via " .. tostring(norm or "global Normal") .. ")")
  end
end
table.insert(out, "__DONE__")
vim.fn.writefile(out, "/tmp/nvim-debug-hl-term-out.txt")
EOF
tmux send-keys -t "$session" ':luafile '"$probe" Enter
for i in $(seq 1 10); do
  grep -q '__DONE__' "$out" 2>/dev/null && break
  sleep 1
done
cat "$out"
```

`effective Normal fg` が想定と違う色なら、そのウィンドウの `winhighlight` に `Normal:X`（X がその悪い色のグループ）が設定されているのが原因。X を設定しているプラグイン（ツリー・ファインダー・ターミナル系等が、ターミナルウィンドウに独自の winhighlight を漏れ出させることは珍しくない）を特定して対処する。

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
* エラーメッセージをcaptureで読むとnoiceのポップアップ等で途切れる。正確な全文が必要なら必ずファイル経由で取る。`vim.notify()` 由来の通知は `:messages` ではなくNoice履歴側にだけ残ることがある
* capture結果は `grep -v '^$'` で空行を落とすと読みやすい。全体が必要なら `-S -50` で履歴も含める
* `capture-pane` が空を返したら、直前のsend-keysが反映される前に読んでいる。sleepを増やして再取得する
* 同名セッションが残っているときは再利用しない。既存のNeovim画面へsend-keysしてバッファを汚す可能性があるため、必ず別名セッションを作る
* 非TTY のシェル（Agent の Bash tool 等）から非デタッチの `tmux new-session` を実行すると `open terminal failed: not a terminal` になる。この環境では `tmux new-session -d`（デタッチ）を使い、必要なら `tmux attach -t <session>` を案内する
* `:lua` 内で `vim.cmd("normal! <Esc>")` を実行すると不要なキー送信が起き、バッファに `c>` が混入することがある。`:lua` 実行時は visual が既に解除されているため、この行自体が不要（削除して解決する）
* `:lua` 内で `vim.cmd("normal! o")` を実行すると autoindent が効かず、`vim.fn.setline(".", ...)` で行を書き換えるとインデントが消える。事前に `vim.fn.getline("."):match("^%s*")` で現在行のインデントを取得して付与する
* Bash tool の呼び出しは毎回独立プロセスで、前回設定したシェル変数（`session=nvim-debug` 等）は次回は空になる。変数が空のまま `tmux kill-session -t "$session"` を実行すると `-t ""` になり、tmux は「現在のセッション」＝Agent自身が動いているユーザーの作業セッションを kill してしまう（実害あり: dotfiles セッション削除事故）。`send-keys -t ""` も同様に現在セッションのアクティブペイン（ユーザーのNeovim）へ誤送信しうる。セッション名を tmux コマンドへ渡す際は変数に頼らず、ハードコードした名前を直接指定するか、同一の Bash 呼び出し内で設定と使用を完結させる。破壊的コマンドの直前には `echo "$VAR"` で値を確認する
* デバッグ用コマンドの失敗を `2>/dev/null || true` で握りつぶさない。kill-session 等の後始末が失敗していても気づけず、ゴミセッションや誤操作が残る。エラーを握りつぶす `|| true` を使う場合は、続けて対象セッションの存在確認（`tmux has-session -t <name>`）を行う

## Safety rules

* Agentのシェルで nvim / nvr を直接実行しない（headless含む）。必ずtmuxセッション内で起動する
* `:Lazy update` や `:Lazy sync` など状態を変える操作は、ユーザーの明示的な指示がある場合のみ実行する
* デバッグ完了後はセッションを kill する。ユーザーと共同作業中のセッションは残し、ユーザーに判断を委ねる
