--vim.cmd [[
--set updatetime=500
--highlight LspReferenceText  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
--highlight LspReferenceRead  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
--highlight LspReferenceWrite cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
--augroup lsp_document_highlight
--autocmd!
--autocmd CursorHold,CursorHoldI * lua if vim.bo.filetype ~= 'NvimTree' then vim.lsp.buf.document_highlight() end
--autocmd CursorMoved,CursorMovedI * lua if vim.bo.filetype ~= 'NvimTree' then vim.lsp.buf.clear_references() end
--augroup END
--]]

vim.o.updatetime = 700
vim.cmd([[
  highlight LspReferenceText  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
  highlight LspReferenceRead  cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
  highlight LspReferenceWrite cterm=underline ctermfg=1 ctermbg=8 gui=underline guifg=#A00000 guibg=#104040
  augroup lsp_hover
  autocmd!
  autocmd CursorHold,CursorHoldI * lua require'lsp-hover'.on_cursor_hold()
  augroup END
]])

require("noice").setup({
  routes = {
    {
      filter = {
        event = "notify",
        find = "No information available",
      },
      opts = { skip = true },
    },
    {
      filter = {
        event = "notify",
        find = "method textDocument/hover is not supported by any of the servers registered for the current buffer",
      },
      opts = { skip = true },
    },
  },
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
