-- lazygit 終了時に残ったウィンドウを掃除する。
--
-- 「バッファ名が空」の条件はフロートに限定する。分割ウィンドウまで対象にすると、
-- no-neck-pain の余白（名前が空の分割）を閉じてしまい、隣の Agent ターミナルの幅が
-- 変わって SIGWINCH が飛ぶ。Claude Code はリサイズのたびに TUI を描き直すため、
-- 文字が二重に表示される原因になっていた。
local M = {}

local CLEANUP_FILETYPES = {
  lazygit = true,
  cmp_menu = true,
  NvimSeparator = true,
}

local function is_float(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function should_close(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if CLEANUP_FILETYPES[vim.bo[buf].filetype] then
    return true
  end
  return is_float(win) and vim.api.nvim_buf_get_name(buf) == ""
end

-- 指定タブ内だけを掃除する。nvim_list_wins() は全タブを返すため使わない。
-- @param tabpage number
function M.cleanup(tabpage)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.api.nvim_win_is_valid(win) and should_close(win) then
      if #vim.api.nvim_tabpage_list_wins(tabpage) > 1 then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

return M
