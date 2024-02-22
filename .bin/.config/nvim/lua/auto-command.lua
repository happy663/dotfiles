-- この関数をグローバルスコープに定義
function on_cursor_hold()
  if vim.bo.filetype ~= "NvimTree" then
    vim.lsp.buf.hover()
  end
end

-- `updatetime`を設定
vim.o.updatetime = 700
-- LSP関連のハイライト設定
vim.cmd([[
highlight LspReferenceText  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
highlight LspReferenceRead  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
highlight LspReferenceWrite cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
]])

-- autocmdグループを定義し、CursorHoldとCursorHoldIイベントでon_cursor_hold関数を呼び出す
vim.api.nvim_create_augroup("lsp_hover", {})
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = "lsp_hover",
  pattern = "*",
  callback = on_cursor_hold, -- ここで直接関数を指定
})

vim.cmd([[
  autocmd BufLeave * silent! update
  autocmd BufUnload * silent! update
]])

vim.cmd([[
  autocmd CursorHold * silent! update
]])

vim.cmd([[
  autocmd BufWritePost *.lua source <afile> | echo "Configuration reloaded!"
]])

vim.api.nvim_create_autocmd("CursorMoved", {
  pattern = "*",
  callback = function()
    vim.cmd("normal! zz")
  end,
})

local function auto_update_path()
  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if vim.fn.isdirectory(bufname) or vim.fn.isfile(bufname) then
    require("nvim-tree.api").tree.find_file(vim.fn.expand("%:p"))
  end
end

vim.api.nvim_create_autocmd("BufEnter", { callback = auto_update_path })
