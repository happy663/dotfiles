-- レビューコメント挿入モジュール
-- Markdown 系は blockquote（> 📝 review-comment: ...）形式 + 番号マーカー方式
-- コード系は言語のコメント記号（--, //, # など）で行直下に挿入する

local M = {}

-- blockquote 形式を使うファイルタイプ
local MARKDOWN_FILETYPES = {
  markdown = true,
  mdx = true,
  pandoc = true,
  rst = true,
}

-- コードファイル用のコメント記号を返す（commentstring 優先、フォールバックは #）
local function code_comment_prefix()
  local ft = vim.bo.filetype
  local cs = vim.bo.commentstring
  if cs and cs:find("%%s") then
    return cs:gsub("%%s", ""):gsub("%s*$", ""):gsub("^%s*", "")
  end
  local map = {
    lua = "--",
    vim = '"',
    python = "#",
    sh = "#",
    zsh = "#",
    bash = "#",
    fish = "#",
    typescript = "//",
    typescriptreact = "//",
    javascript = "//",
    javascriptreact = "//",
    c = "//",
    cpp = "//",
    csharp = "//",
    go = "//",
    rust = "//",
    java = "//",
    kotlin = "//",
    swift = "//",
    ruby = "#",
    perl = "#",
    yaml = "#",
    toml = "#",
    ini = ";",
    conf = "#",
    sql = "--",
    haskell = "--",
    elixir = "#",
    clojure = ";",
    scala = "//",
    php = "//",
    zig = "//",
  }
  return map[ft] or "#"
end

-- バッファ内の既存 review-comment 番号の最大値+1を返す
local function next_review_comment_number()
  local max_num = 0
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local num = line:match("review%-comment:%s*%[(%d+)%]")
    if num then
      max_num = math.max(max_num, tonumber(num))
    end
  end
  return max_num + 1
end

-- ファイルタイプに応じたレビューコメント行を組み立てる
local function review_comment_line(body)
  if MARKDOWN_FILETYPES[vim.bo.filetype] then
    return "> 📝 review-comment: " .. body
  end
  return code_comment_prefix() .. " review-comment: " .. body
end

-- 現在行の直下にコメントを挿入して insert モードへ
local function insert_review_comment_line(body)
  -- :lua 経由の normal! o では autoindent が効かないため、現在行のインデントを明示的に保持する
  local indent = vim.fn.getline("."):match("^%s*")
  vim.cmd("normal! o")
  vim.fn.setline(".", indent .. review_comment_line(body))
  vim.cmd("startinsert!")
end

-- 文字単位選択: 選択範囲の直後に [N] を挿入し、その行の直下に採番コメントを挿入
local function utf8_char_len(byte)
  if byte >= 0xF0 then
    return 4
  elseif byte >= 0xE0 then
    return 3
  elseif byte >= 0xC0 then
    return 2
  end
  return 1
end

local function insert_range_review_comment()
  local num = next_review_comment_number()
  local marker = "[" .. num .. "]"

  -- 選択範囲の終了位置を取得（'> は1-indexed、バイト単位）
  local end_line = vim.fn.line("'>")
  local end_col = vim.fn.col("'>")

  -- 選択範囲の直後（カーソル位置の文字の後ろ）にマーカーを挿入
  local lines = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)
  local line = lines[1]
  local insert_byte = end_col - 1 -- 0-indexed
  if insert_byte < #line then
    -- UTF-8 文字を途中で切らないよう、文字のバイト長ぶん進める
    insert_byte = insert_byte + utf8_char_len(line:byte(insert_byte + 1))
  end
  local new_line = line:sub(1, insert_byte) .. marker .. line:sub(insert_byte + 1)
  vim.api.nvim_buf_set_lines(0, end_line - 1, end_line, false, { new_line })

  -- コメントを挿入する行へ移動して直下に挿入
  vim.fn.cursor(end_line, 0)
  insert_review_comment_line("[" .. num .. "] ")
end

function M.insert_review_comment_normal()
  insert_review_comment_line("")
end

-- visual モード用（コマンド文字列ベースのマッピングから呼ばれる）
-- Lua コールバックベースの visual マッピングはこの環境で発火しないため、
-- vim.api.nvim_set_keymap + :lua で定義している
function M.insert_review_comment_visual()
  local vmode = vim.fn.visualmode()
  if MARKDOWN_FILETYPES[vim.bo.filetype] and vmode == "v" then
    -- Markdown の文字単位選択: 番号マーカー方式
    insert_range_review_comment()
  else
    -- コード or V / 矩形選択: 選択最終行の直下（行単位レビュー）
    vim.fn.cursor(vim.fn.line("'>"), 0)
    insert_review_comment_line("")
  end
end

return M
