---
name: nvim-perf-bench
description: |
  Neovimの特定バッファで「カーソル移動や入力が重い」「カクつく」「遅い」原因を、
  tmux内の実Neovimでキー入力を再現して計測し、原因の切り分け・解消策の効果測定・見た目の等価性確認まで行う。
  「このバッファが重い」「入力が遅い」「スクロールがもたつく」「パフォーマンスを改善したい」
  「Octo/markdownが重い」などのリクエストで使用する。推測ではなく関数単位の実測で原因を特定する。
---

# Neovim 入力遅延の計測と改善

## 前提

* Neovim の起動・操作は `debug-nvim-tmux` スキルの手順で行う（Agent のシェルで nvim / nvr を直接実行しない）。起動は `env NVIM= command nvim`、操作は `send-keys` + ファイル経由の出力回収
* 計測ハーネスはこのスキルの `scripts/bench.lua`。スクラッチパッドにコピーせず、スキル内のパスを直接 `dofile` する（スクラッチパッドは日をまたぐと消えることがある）
* スキルの実パス: `$(ghq root)/github.com/happy663/dotfiles/conf/.config/ai-agents/skills/nvim-perf-bench`

## 進め方

### 1. 再現する

1. `debug-nvim-tmux` の手順で、普段の設定のまま Neovim を tmux 内に起動する（`-x 200 -y 50` 程度で実画面に近いサイズにする）
2. 起動直後はダッシュボードがキーを食うので、`Escape` を送ってから `:` コマンドを送る
3. 重いバッファを開き、非同期読み込み（Octo 等）なら行数が安定するまでポーリングで待つ

### 2. 状況を把握する

疑う前に、そのウィンドウで何が動いているかをファイルに書き出す。

* ウィンドウオプション: `statuscolumn` `foldmethod` `foldexpr` `foldtext` `conceallevel` `wrap` `linebreak` `cursorline` `winhighlight`
* グローバル: `lazyredraw` `updatetime` `laststatus` `cmdheight`
* namespace ごとの extmark 数（`nvim_get_namespaces` + `nvim_buf_get_extmarks`）
* treesitter の言語ツリー数（`parser:for_each_tree`。markdown_inline が行ごとに大量に出るのは普通）
* 現在バッファに効く autocmd と定義元: `P.list_autocmds()`
* `getmatches()`（matchadd の数）

### 3. ベースラインを測る

ラン用の Lua をスクラッチパッドに書き、`:luafile` で読み込む。

```lua
local SKILL = vim.fn.expand("~/src/github.com/happy663/dotfiles/conf/.config/ai-agents/skills/nvim-perf-bench")
local P = dofile(SKILL .. "/scripts/bench.lua")
P.setup({ out = "<scratchpad>/results.txt" })

-- v:lua.require(...) 経由で毎行呼ばれる関数は wrap して呼び出し回数と時間を数える
P.wrap("octo.ui.statuscolumn", "statuscolumn", "statuscol")
P.wrap("plugins.git.octo.fold", "octo_fold_all", "foldexpr")

local win = vim.api.nvim_get_current_win()
local function at(pat)
  return function() vim.api.nvim_win_set_cursor(win, { P.find_line(pat), 0 }) end
end
P.sequence({
  { label = "base [j/k]", setup = at("本文の目印"), keys = P.concat(P.rep("j", 40), P.rep("k", 40)) },
  { label = "base [insert]", setup = at("本文の目印"),
    keys = P.concat({ "A" }, P.rep("x", 30), { "<Esc>", "u" }),
    measure = function(_, k) return k == "x" end },
  { label = "base [hold j]", setup = at("本文の目印"), keys = P.rep("j", 60), interval = 33, tail = 3000 },
})
```

`results.txt` に `__SEQ_DONE__` が出るまでポーリングして読む。

指標の読み方:

* `lat`: キーから最初の再描画完了まで。体感の「もたつき」。p90 / max を見る
* `cpu/key`: 1キーで消費した CPU 時間。後から走る処理（schedule・タイマー・TextChanged）も含むので、`lat` が小さくても `cpu/key` が送信間隔（120ms なら 120ms）に近いと、速く打つと詰まる
* `wrap` 列: 包んだ関数が1キーで何回・何 ms 走ったか。ここが `cpu/key` の大半なら犯人

同じ条件で2回以上測る。初回はキャッシュ状態でぶれる。

### 4. 切り分ける

ステップの `setup` で1つ止め、`teardown` で戻しながら同じキー列を測る。差が大きいものが原因。

よくある候補と止め方:

| 候補 | 止め方（setup） |
|---|---|
| statuscolumn | `vim.wo[win].statuscolumn = ""` |
| foldexpr | `vim.wo[win].foldmethod = "manual"` |
| render-markdown | `require("render-markdown").buf_disable()`（`nvim_win_call` 内で） |
| treesitter highlight | `vim.treesitter.stop(buf)` |
| CursorMoved の autocmd | `nvim_get_autocmds` で探して `nvim_del_autocmd`、teardown で同じ callback を再登録 |
| smear-cursor | `require("smear_cursor").enabled = false` |
| conceal | `vim.wo[win].conceallevel = 0` |
| wrap | `vim.wo[win].wrap = false` |

原因の関数が絞れたら、`P.micro(fn, n, args...)` で1回あたりの時間を測る。

### 5. プロファイルで中身を見る

原因の関数の中で何が重いかは `jit.p` で見る。

```lua
{ label = "prof [insert]", keys = ..., measure = ...,
  setup = function() P.profile_start("<scratchpad>/prof.txt") end,
  teardown = P.profile_stop },
```

`query.lua:iter` や `languagetree.lua:tcall` が上位なら treesitter のクエリが行ごとに走っている。conceal の判定（`TSHighlighter._on_conceal`）は編集した行のキャッシュを消すため、挿入モードで顕著に重くなる。

### 6. その場で差し替えて効果を測る

設定ファイルを触る前に、Neovim の中で関数を差し替えて効果を測る。

* `M.fn` 経由で呼ばれる関数なら、モジュールテーブルの関数を置き換えれば効く
* 上流のローカル変数（upvalue）が必要なら `debug.getupvalue(fn, i)` で名前から取り出す
* 差し替え版を `P.patch_on` / `P.patch_off` のような関数にして、sequence の setup で切り替え、前後を同じ条件で測る
* 下限の参考として、その機能自体を無効にした場合も測る。差し替え版がそこに近ければ、残りのコストはほぼゼロ

### 7. 見た目・機能が変わらないことを確かめる

* 実バッファの全行（折り返しも含め、`nvim_win_text_height` で各行の画面行数を出して virtnum ごと）で、元の関数と差し替え版の出力を `P.compare` で比べる。不一致 0 を確認する
* 実バッファにない状態（閉じた fold、長い折り返し行、1行だけの範囲、未保存状態など）は、`:tabnew` した合成バッファで作って同じ比較をする
* `capture-pane` で見た目を目視確認する

このスキルの範囲はここまで。設定への組み込み方（どのファイルに置くか、テストの書き方、コミット）は呼び出し側に委ねる。組み込んだ後に効果を確かめたい場合は、普段の設定で起動し直して手順3と同じ計測をする。

## 報告の形

* 原因（ファイル:行、なぜ重いか、どの条件で重くなるか）
* 解消策と、見た目・機能が変わらない根拠（比較した行数と不一致数）
* 現状 / 差し替え版 / 機能を無効にした場合（下限）の表（`lat` p90・max、`cpu/key`）
* 残っているコストの内訳（削る必要があるかの判断付き）

## 教訓（実際に踏んだもの）

* 推測した原因は外れることがある。Octo の重さでは、最初に疑った O(n²) の foldexpr は 1キー 0.01ms で無関係だった。犯人は octo 本体の statuscolumn（`nvim_win_text_height` で範囲全体の高さを毎行数え直していた）。必ず `P.wrap` で関数単位に測ってから判断する
* 「見た目を削る」前に、同じ結果をより安く出せないかを考える。今回は `max_height = 2` で数え打ちを止めるだけで、statuscolumn を無効にしたのと同じ速さになった
* 重さはバッファの内容に依存する。長い1ブロック（PR本文など）、長い折り返し行、conceal、インライン仮想テキストがあると、行の表示高さの計算が重くなる。軽いバッファで測っても再現しない

## 注意

* Octo などの書き込みが外部に出るバッファでは、絶対に `:w` しない。挿入テストは `<Esc>` `u` で戻し、終了は `:qa!`
* `P.run` は `nvim_input` をタイマーから送るので、計測中に別の `send-keys` を送らない
* 終わったら tmux セッションを `kill-session` する。セッション名は変数に頼らず直接書く（`debug-nvim-tmux` の注意参照）
