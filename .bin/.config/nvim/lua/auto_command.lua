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
      --filter = {
      --event = "notify",
      --find = "method textDocument/hover is not supported by any of the servers registered for the current buffer",
      --},
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

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  -- 枠のスタイルを指定します: single, double, rounded, solid, shadow など
  border = "rounded",
})
