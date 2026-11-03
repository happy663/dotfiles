-- カーソル行への Obsidian リンク（[[ノート名#^ID]]）を作ってコピーする。
-- Obsidian アプリの「ブロックへのリンクをコピー」に相当する操作を Neovim で行うためのもの。
-- obsidian.nvim は既存のブロックIDの補完・ジャンプには対応しているが、IDの付与はしないため自前で行う。
local M = {}

local ID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"
local ID_LENGTH = 6

-- obsidian.nvim の util.BLOCK_PATTERN（%^[%w%d][%w%d-]*）に合わせて行末の既存IDを拾う
local EXISTING_ID_PATTERN = "%s%^([%w][%w-]*)%s*$"
local HEADING_PATTERN = "^#+%s+(%S.-)%s*$"

--- Obsidian アプリと同じ形式（英小文字と数字の6文字）のIDを作る。
--- math.random はシード次第で起動ごとに同じ系列になりうるため、OS の乱数を使う。
---@return string
function M.generate_id()
  local bytes = assert(vim.uv.random(ID_LENGTH))
  local chars = {}
  for i = 1, ID_LENGTH do
    local idx = bytes:byte(i) % #ID_CHARS + 1
    chars[i] = ID_CHARS:sub(idx, idx)
  end
  return table.concat(chars)
end

--- カーソル行へのリンクを作り、+ と " レジスタにコピーする。
--- 見出し行は見出しリンク、それ以外はブロックIDを使う（なければ行末に付ける）。
---@param opts? { gen_id?: fun(): string }
---@return string|nil link
function M.copy(opts)
  opts = opts or {}
  local gen_id = opts.gen_id or M.generate_id
  local bufnr = vim.api.nvim_get_current_buf()

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.notify("ファイル名のないバッファではリンクを作れません", vim.log.levels.WARN)
    return nil
  end
  local note_name = vim.fn.fnamemodify(path, ":t:r")

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  if vim.trim(line) == "" then
    vim.notify("空行にはブロックIDを付けられません", vim.log.levels.WARN)
    return nil
  end

  local link
  local heading = line:match(HEADING_PATTERN)
  if heading then
    link = string.format("[[%s#%s]]", note_name, heading)
  else
    local id = line:match(EXISTING_ID_PATTERN)
    if not id then
      id = gen_id()
      -- 末尾の空白ごと置き換えて「本文 ^ID」の形にする（カーソルより前は触らない）
      local content_end = #(line:gsub("%s+$", ""))
      vim.api.nvim_buf_set_text(bufnr, row - 1, content_end, row - 1, #line, { " ^" .. id })
    end
    link = string.format("[[%s#^%s]]", note_name, id)
  end

  vim.fn.setreg("+", link)
  vim.fn.setreg('"', link)
  vim.notify("コピーしました: " .. link)
  return link
end

return M
