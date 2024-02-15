local M = {}

function M.on_cursor_hold()
  if vim.bo.filetype == "NvimTree" then
    return
  end
  vim.lsp.buf.hover()
end

return M
