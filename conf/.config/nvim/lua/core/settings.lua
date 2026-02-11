-- settings.lua

-- UI設定
vim.o.number = true -- 行番号を表示
vim.o.relativenumber = true -- 現在行からの相対的な行番号表示
vim.o.cursorline = true -- カーソル位置の行をハイライト
vim.o.showmatch = true -- 括弧のマッチング部分を表示
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







vim.api.nvim_set_hl(0, "Comment", { fg = "#7c869c" })
vim.api.nvim_set_hl(0, "@Comment", { fg = "#7c869c" })



-- ayu_mirageに調和する検索ハイライトの設定
local colors = {
  bg = "#1f2420", -- ayu_mirageの背景色
  fg = "#cbccc6", -- 基本的な文字色
  search = {
    current = {
      fg = "#1f2420", -- 暗めの背景色
      bg = "#ffd685", -- より鮮やかな黄金色（現在の検索位置）
    },
    normal = {
      fg = "#1f2420",
      bg = "#c5c5c5", -- より控えめな色（通常の検索マッチ）
    },
    near = {
      fg = "#1f2420",
      bg = "#d4bfff", -- 柔らかい紫（近いマッチ）
    },
    mid = {
      fg = "#1f2420",
      bg = "#80bfff", -- ソフトなティール（画面内のマッチ）
    },
    far = {
      fg = "#1f2420",
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
    autocmd ColorScheme * highlight IncSearch guibg=#fcdc9d guifg=#1f2420 gui=bold,undercurl
    autocmd ColorScheme * highlight Search guibg=#c5c5c5 guifg=#1f2420 gui=NONE
  augroup END
]])



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
  fg = "#1f2420", -- カーソル上のテキストの色
  bg = "#73d0ff", -- カーソルの背景色（黄金色）
})

-- 挿入モードのカーソル色を変更したい場合
vim.api.nvim_set_hl(0, "iCursor", {
  fg = "#1f2420",
  bg = "#73d0ff", -- 青みがかった色
})

-- ビジュアルモードのカーソル色
vim.api.nvim_set_hl(0, "vCursor", {
  fg = "#1f2420",
  bg = "#f28779", -- サーモンピンク
})

-- カラースキーム変更時にカーソルの色を保持
vim.cmd([[
  augroup CursorColor
    autocmd!
    autocmd ColorScheme * highlight Cursor guifg=#1f2420 guibg=#73d0ff
    autocmd ColorScheme * highlight iCursor guifg=#1f2420 guibg=#73d0ff
    autocmd ColorScheme * highlight vCursor guifg=#1f2420 guibg=#f28779
  augroup END
]])
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

vim.o.grepprg = "git grep -n --no-color"
vim.opt.grepformat = "%f:%l:%m"
-- vim.o.clipboard = "unnamedplus"

-- Markdownのスペルチェックハイライトを白色に設定
-- (デフォルトではCommentと同じ灰色になってしまうため)

vim.api.nvim_set_hl(0, "@spell", { fg = "#c8d3f5" })
vim.api.nvim_set_hl(0, "@spell.markdown", { fg = "#c8d3f5" })

-- -- HTTPリンクのハイライト設定（Treesitterカスタムクエリ用）
-- vim.api.nvim_set_hl(0, "@markup.link.url.http", {
--   fg = "#82aaff", -- 明るい青色（tokyonight-moonに調和）
--   underline = true,
-- })

vim.g.toggle_markdown_color = true

vim.keymap.set("n", "<leader>tz", function()
  if vim.g.toggle_markdown_color then
    vim.api.nvim_set_hl(0, "@spell", { fg = "#7c869c" })
    vim.api.nvim_set_hl(0, "@spell.markdown", { fg = "#7c869c" })
    vim.g.toggle_markdown_color = false
  else
    vim.api.nvim_set_hl(0, "@spell", { fg = "#c8d3f5" })
    vim.api.nvim_set_hl(0, "@spell.markdown", { fg = "#c8d3f5" })
    vim.g.toggle_markdown_color = true
  end
end)

vim.api.nvim_set_hl(0, "mkdNonListItemBlock", { fg = "#c8d3f5" })
vim.api.nvim_set_hl(0, "mkdListItemLine", { fg = "#c8d3f5" })

-- Markdownの折りたたみ関数（<details>タグとコードブロックの両方に対応）
function _G.octo_fold_all()
  local line = vim.fn.getline(vim.v.lnum)

  -- <details>タグの処理を優先
  if line:match("^%s*<details") then
    return ">1"
  elseif line:match("^%s*</details>") then
    return "<1"
  end

  -- コードブロックの処理
  if line:match("^```") then
    -- 現在行より前の```の数を数える
    local count = 0
    for i = 1, vim.v.lnum - 1 do
      local prev_line = vim.fn.getline(i)
      if prev_line:match("^```") then
        count = count + 1
      end
    end

    -- 偶数個目（開始タグ）の場合、ブロックの行数をチェック
    if count % 2 == 0 then
      -- 対応する終了タグを探す
      local total_lines = vim.fn.line("$")
      local end_line = nil
      for i = vim.v.lnum + 1, total_lines do
        if vim.fn.getline(i):match("^```") then
          end_line = i
          break
        end
      end

      -- ブロックの行数を計算（開始と終了を除く）
      if end_line then
        local block_lines = end_line - vim.v.lnum - 1
        if block_lines >= 20 then
          return ">1" -- 20行以上なら折りたたみ開始
        end
      end
      return "=" -- 20行未満なら折りたたまない
    else
      -- 奇数個目（終了タグ）の場合、対応する開始タグをチェック
      -- 開始タグで折りたたみ判定済みなので、開始タグが折りたたみ開始なら終了
      for i = vim.v.lnum - 1, 1, -1 do
        if vim.fn.getline(i):match("^```") then
          -- この開始タグが20行以上のブロックかチェック
          if vim.v.lnum - i - 1 >= 20 then
            return "<1" -- 折りたたみ終了
          end
          break
        end
      end
      return "=" -- 折りたたまない
    end
  end

  return "=" -- 前の行のレベルを継承
end

-- 折りたたまれたテキストの表示をカスタマイズ
function _G.octo_foldtext()
  local line = vim.fn.getline(vim.v.foldstart)

  -- コードブロックの場合
  if line:match("^```") then
    local lang = line:match("^```(%w+)") or "code"
    local lines_count = vim.v.foldend - vim.v.foldstart - 1
    return "  " .. lang .. " (" .. lines_count .. " lines) ......................................."
  end

  if line:match("<details>") then
    local summary = "詳細"
    -- 折りたたまれた範囲内でsummaryタグを探す
    for i = vim.v.foldstart, vim.v.foldend do
      local l = vim.fn.getline(i)
      local match = l:match("<summary>(.-)</summary>")
      if match then
        summary = match
        break
      end
    end
    return "  " .. summary .. " "
  end

  return vim.fn.foldtext()
end

-- 折りたたみのハイライト設定
vim.api.nvim_set_hl(0, "Folded", {
  fg = "#82aaff", -- 明るい青色（tokyonight-moonに調和）
  bg = "#1e2030", -- 少し暗めの背景
  italic = true,
})

vim.api.nvim_set_hl(0, "FoldColumn", {
  fg = "#636da6",
  bg = "NONE",
})

-- 折りたたみ記号の設定
vim.opt.fillchars:append({
  fold = " ",
  foldopen = "▾",
  foldclose = "▸",
  foldsep = " ",
})


vim.opt.foldlevel = 99 -- デフォルトでは全て展開
vim.opt.foldlevelstart = 99 -- ファイルを開いたときは全て展開
-- vim.o.foldtext = "" -- 任意; 既定の折り畳み表示が嫌いな人用
vim.o.synmaxcol = 200
vim.o.laststatus = 3






