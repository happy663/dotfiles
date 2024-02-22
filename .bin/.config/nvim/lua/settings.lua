-- settings.lua

-- UI設定
vim.o.number = true -- 行番号を表示
vim.o.relativenumber = true -- 現在行からの相対的な行番号表示
vim.o.cursorline = true -- カーソル位置の行をハイライト
vim.o.showmatch = true -- 括弧のマッチング部分を表示
vim.o.foldmethod = "marker" -- 折りたたみの方法をマーカーに設定
--vim.o.colorcolumn = '80'          -- 80文字目に縦線を表示
vim.o.splitright = true -- 垂直分割時に新しいウィンドウを右側に表示
vim.o.splitbelow = true -- 水平分割時に新しいウィンドウを下側に表示
vim.o.termguicolors = true -- True color support

-- エディタ設定
vim.o.expandtab = true -- タブをスペースに変換
vim.o.tabstop = 2 -- タブの幅を2スペースに設定
vim.o.shiftwidth = 2 -- インデントの幅を2スペースに設定
vim.o.smartindent = true -- 自動インデント機能を有効化
vim.o.wrap = false -- 長い行を折り返さない
vim.o.clipboard = "unnamedplus" -- システムクリップボードを使用

-- 検索設定
vim.o.hlsearch = true -- 検索結果をハイライト
vim.o.incsearch = true -- インクリメンタル検索を有効化
vim.o.ignorecase = true -- 検索時に大文字と小文字を区別しない
vim.o.smartcase = true -- 検索クエリに大文字が含まれている場合のみ大文字と小文字を区別

-- バックアップとスワップファイルを無効化
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false

-- キーマップのリーダーキーをスペースに設定
vim.g.mapleader = " "

-- コマンドラインの高さ
vim.o.cmdheight = 1

-- 補完の設定
vim.o.completeopt = "menuone,noselect"

-- マウスサポート
vim.o.mouse = "a"

-- 起動画面を無効化
vim.opt.shortmess:append("sI")

-- デフォルトのカラースキームを設定
vim.cmd("colorscheme ayu-mirage")

-- 折り返し
vim.o.wrap = true
