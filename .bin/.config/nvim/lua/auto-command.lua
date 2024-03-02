local autocmd = vim.api.nvim_create_autocmd
local set_hl = vim.api.nvim_set_hl

vim.o.updatetime = 300

local function on_cursor_hold()
  if vim.bo.filetype ~= "NvimTree" then
    vim.lsp.buf.hover()
  end
end

local lsp_hover_group = vim.api.nvim_create_augroup("lsp_hover", { clear = true })
autocmd({ "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  group = lsp_hover_group,
  callback = on_cursor_hold, -- ここで直接関数を指定
})

-- LSPのハイライトを設定
set_hl(0, "LspReferenceText", { underline = true, ctermfg = 1, ctermbg = 8, fg = "#A00000", bg = "#104040" })
set_hl(0, "LspReferenceRead", { underline = true, ctermfg = 1, ctermbg = 8, fg = "#A00000", bg = "#104040" })
set_hl(0, "LspReferenceWrite", { underline = true, ctermfg = 1, ctermbg = 8, fg = "#A00000", bg = "#104040" })

-- 自動ファイル保存
-- markdonw以外のファイルを自動で保存する
autocmd({ "BufLeave", "BufUnload", "CursorHold" }, {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype
    if filetype ~= "markdown" then
      vim.cmd("silent! update")
    end
  end,
})

vim.api.nvim_create_augroup("MemoAutoCommit", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = "MemoAutoCommit",
  pattern = "*/.memolist/memo/*.md",
  command = "!(memo commit)",
})

-- luaファイル保存時に設定をリロード
autocmd("BufWritePost", { pattern = "*.lua", command = "source <afile> | echo 'Configuration reloaded!'" })

-- カーソルを画面中央になるようにする
autocmd("CursorMoved", { pattern = "*", command = "normal! zz" })

local function auto_open_tree_file()
  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) or vim.fn.isfile(bufname) then
    require("nvim-tree.api").tree.find_file(vim.fn.expand("%:p"))
  end
end

autocmd("BufEnter", { pattern = "*", callback = auto_open_tree_file })
