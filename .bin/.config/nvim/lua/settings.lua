-- settings.lua

-- UI設定
vim.o.number = true -- 行番号を表示
vim.o.relativenumber = true -- 現在行からの相対的な行番号表示
vim.o.cursorline = true -- カーソル位置の行をハイライト
vim.o.showmatch = true -- 括弧のマッチング部分を表示
vim.o.foldmethod = "marker" -- 折りたたみの方法をマーカーに設定
vim.o.colorcolumn = "80" -- 80文字目に縦線を表示
vim.o.splitright = true -- 垂直分割時に新しいウィンドウを右側に表示
vim.o.splitbelow = true -- 水平分割時に新しいウィンドウを下側に表示
vim.o.termguicolors = true -- True color support

-- エディタ設定
vim.o.expandtab = true -- タブをスペースに変換

vim.o.tabstop = 2 -- タブの幅を2スペースに設定
-- Add the keymap for <C-n> in henkan mode
vim.o.shiftwidth = 2 -- インデントの幅を2スペースに設定
vim.o.smartindent = true -- 自動インデント機能を有効化
vim.o.wrap = false -- 長い行を折り返さない

-- 検索設定
vim.o.hlsearch = true -- 検索結果をハイライト
vim.o.incsearch = true -- インクリメンタル検索を有効化
vim.o.ignorecase = true -- 検索時に大文字と小文字を区別しない
vim.o.smartcase = true -- 検索クエリに大文字が含まれている場合のみ大文字と小文字を区別

-- バックアップとスワップファイルを無効化
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false

-- コマンドラインの高さ
vim.o.cmdheight = 1

-- 補完の設定
vim.o.completeopt = "menuone,noselect"

-- マウスサポート
vim.o.mouse = "a"

-- 起動画面を無効化
vim.opt.shortmess:append("sI")

vim.o.encoding = "utf-8"
vim.o.fileencodings = "utf-8,euc-jp"

-- デフォルトのカラースキームを設定
vim.cmd("colorscheme ayu-mirage")

require("notify").setup({
  background_colour = "#000000",
})

---- 現在選択中のアイテムのハイライト色を変更
vim.cmd([[highlight TelescopeSelection guibg=#083747]])
vim.cmd([[highlight TelescopePreviewLine guibg=#083747]])

vim.api.nvim_set_hl(0, "Comment", { fg = "#7c869c" })
vim.api.nvim_set_hl(0, "@Comment", { fg = "#7c869c" })

vim.g.lazygit_floating_window_scaling_factor = 1

vim.api.nvim_set_hl(0, "IncSearch", { fg = "#000000", bg = "#ff99cc" })
vim.api.nvim_set_hl(0, "Search", { fg = "#ffffff", bg = "#008000" })

-- HlSearchLensNear、HlSearchLens、HlSearchLensFar は、検索マッチが画面に近い、画面内、画面から遠い場合に使用されます。
vim.api.nvim_set_hl(0, "HlSearchLensNear", { fg = "#ffffff", bg = "#ff99cc" }) -- 近いマッチにはIncSearchと同じ色
vim.api.nvim_set_hl(0, "HlSearchLens", { fg = "#000000", bg = "#bae67e" }) -- 中間のマッチには明るい緑
vim.api.nvim_set_hl(0, "HlSearchLensFar", { fg = "#ffffff", bg = "#5ccfe6" }) -- 遠いマッチには明るいブルー

vim.g.vsnip_snippet_dir = "~/.config/nvim/my_snippets"

-- <C-d> の再マッピング
vim.api.nvim_set_keymap("n", "<C-d>", "<Cmd>keepjumps normal! <C-d><CR>", { noremap = true, silent = true })

-- <C-u> の再マッピング
vim.api.nvim_set_keymap("n", "<C-u>", "<Cmd>keepjumps normal! <C-u><CR>", { noremap = true, silent = true })

-- { の再マッピング
vim.api.nvim_set_keymap("n", "{", "<Cmd>keepjumps normal! {<CR>", { noremap = true, silent = true })

-- } の再マッピング
vim.api.nvim_set_keymap("n", "}", "<Cmd>keepjumps normal! }<CR>", { noremap = true, silent = true })

vim.g.copilot_filetypes = { markdown = false }
