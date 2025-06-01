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
vim.cmd("colorscheme tokyonight-moon")
-- vim.cmd("colorscheme ayu-mirage")
-- vim.cmd("colorscheme everforest")

require("notify").setup({
  background_colour = "#000000",
})

---- 現在選択中のアイテムのハイライト色を変更
vim.cmd([[highlight TelescopeSelection guibg=#083747]])
vim.cmd([[highlight TelescopePreviewLine guibg=#083747]])
vim.cmd([[highlight TelescopeMatching guifg=#ffd685]])

vim.api.nvim_set_hl(0, "Comment", { fg = "#7c869c" })
vim.api.nvim_set_hl(0, "@Comment", { fg = "#7c869c" })

vim.g.lazygit_floating_window_scaling_factor = 1

-- ayu_mirageに調和する検索ハイライトの設定
local colors = {
  bg = "#1f2430", -- ayu_mirageの背景色
  fg = "#cbccc6", -- 基本的な文字色
  search = {
    current = {
      fg = "#1f2430", -- 暗めの背景色
      bg = "#ffd685", -- より鮮やかな黄金色（現在の検索位置）
    },
    normal = {
      fg = "#1f2430",
      bg = "#c5c5c5", -- より控えめな色（通常の検索マッチ）
    },
    near = {
      fg = "#1f2430",
      bg = "#d4bfff", -- 柔らかい紫（近いマッチ）
    },
    mid = {
      fg = "#1f2430",
      bg = "#80bfff", -- ソフトなティール（画面内のマッチ）
    },
    far = {
      fg = "#1f2430",
      bg = "#80bfff", -- 落ち着いた青（遠いマッチ）
    },
  },
}

-- カーソル位置の検索マッチ（より目立つ）
vim.api.nvim_set_hl(0, "IncSearch", {
  fg = colors.search.current.fg,
  bg = colors.search.current.bg,
  bold = true,
  undercurl = true,
  sp = "#ffd685",
})

-- その他の検索マッチ（より控えめ）
vim.api.nvim_set_hl(0, "Search", {
  fg = colors.search.normal.fg,
  bg = colors.search.normal.bg,
  bold = false,
  underdashed = false,
})

vim.api.nvim_set_hl(0, "HlSearchLensNear", {
  fg = colors.search.near.fg,
  bg = colors.search.near.bg,
  italic = true,
})

vim.api.nvim_set_hl(0, "HlSearchLens", {
  fg = colors.search.mid.fg,
  bg = colors.search.mid.bg,
})

vim.api.nvim_set_hl(0, "HlSearchLensFar", {
  fg = colors.search.far.fg,
  bg = colors.search.far.bg,
})

-- ColorScheme変更時の設定保持
vim.cmd([[
  augroup SearchHighlight
    autocmd!
    autocmd ColorScheme * highlight IncSearch guibg=#fcdc9d guifg=#1f2430 gui=bold,undercurl
    autocmd ColorScheme * highlight Search guibg=#c5c5c5 guifg=#1f2430 gui=NONE
  augroup END
]])

vim.g.vsnip_snippet_dir = "~/.config/nvim/my_snippets"

-- <C-d> の再マッピング
vim.api.nvim_set_keymap("n", "<C-d>", "<Cmd>keepjumps normal! <C-d><CR>", { noremap = true, silent = true })

-- <C-u> の再マッピング
vim.api.nvim_set_keymap("n", "<C-u>", "<Cmd>keepjumps normal! <C-u><CR>", { noremap = true, silent = true })

-- { の再マッピング
vim.api.nvim_set_keymap("n", "{", "<Cmd>keepjumps normal! {<CR>", { noremap = true, silent = true })

-- } の再マッピング
vim.api.nvim_set_keymap("n", "}", "<Cmd>keepjumps normal! }<CR>", { noremap = true, silent = true })

-- カーソルの設定
vim.opt.guicursor = {
  "n-v:block-Cursor", -- ノーマル・ビジュアルモード: ブロックカーソル
  "i-c-ci-ve:ver25-Cursor", -- インサート・コマンドモード: 25%幅の縦線カーソル
  "r-cr:hor20-Cursor", -- 置換モード: 20%高さの横線カーソル
  "o:hor50-Cursor", -- オペレータ待機モード: 50%高さの横線カーソル
  "a:blinkwait500-blinkoff200-blinkon200-Cursor", -- 0.5秒待機、0.2秒オン/オフ
}

-- カーソルカラーの設定
vim.api.nvim_set_hl(0, "Cursor", {
  fg = "#1f2430", -- カーソル上のテキストの色
  bg = "#73d0ff", -- カーソルの背景色（黄金色）
})

-- 挿入モードのカーソル色を変更したい場合
vim.api.nvim_set_hl(0, "iCursor", {
  fg = "#1f2430",
  bg = "#73d0ff", -- 青みがかった色
})

-- ビジュアルモードのカーソル色
vim.api.nvim_set_hl(0, "vCursor", {
  fg = "#1f2430",
  bg = "#f28779", -- サーモンピンク
})

-- カラースキーム変更時にカーソルの色を保持
vim.cmd([[
  augroup CursorColor
    autocmd!
    autocmd ColorScheme * highlight Cursor guifg=#1f2430 guibg=#73d0ff
    autocmd ColorScheme * highlight iCursor guifg=#1f2430 guibg=#73d0ff
    autocmd ColorScheme * highlight vCursor guifg=#1f2430 guibg=#f28779
  augroup END
]])

vim.opt.spell = false
vim.opt.spelllang = { "en", "cjk" }
vim.opt.spelloptions:append("camel", "pascal")

vim.g["diagnostics_active"] = true
function Toggle_diagnostics()
  if vim.g.diagnostics_active then
    vim.g.diagnostics_active = false
    vim.diagnostic.disable()
  else
    vim.g.diagnostics_active = true
    vim.diagnostic.enable()
  end
end

vim.opt.foldmethod = "indent" -- インデントで折りたたみ
vim.opt.foldlevel = 99 -- 折りたたみの初期レベルを99に設定

vim.keymap.set("n", "<Tab>", "zo", { noremap = true, silent = true, desc = "Fold open" })
vim.keymap.set("n", "<S-Tab>", "zc", { noremap = true, silent = true, desc = "Fold close" })
vim.keymap.set("n", "<leader><Tab>", "zR", { noremap = true, silent = true, desc = "Fold open all" })
vim.keymap.set("n", "<leader><S-Tab>", "zM", { noremap = true, silent = true, desc = "Fold close all" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    -- インデント設定
    vim.opt_local.cindent = true
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = true

    -- タブとスペース
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true

    -- PHP特有のインデント調整
    vim.opt_local.cinkeys:remove("0#")
    vim.opt_local.indentkeys:remove("0#")

    -- ★ 波括弧内でのインデントを正しく処理
    vim.opt_local.cinoptions = "j1,(0,ws,Ws,g0,{s,>s,e-s,n-s,+s"
  end,
})

-- tiny-inline-diagnostic.nvimの設定するためコメントアウト
-- vim.diagnostic.config({
-- virtual_lines = true,
-- virtual_text = true,
-- })
