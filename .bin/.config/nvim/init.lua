require("plugins")
require("settings")
require("keymaps")
require("lsp")
require("auto_command")

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  -- 枠のスタイルを指定します: single, double, rounded, solid, shadow など
  border = "rounded",
})

