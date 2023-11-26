vim.opt.fileencoding = "utf-8"                  -- the encoding written to a file
vim.opt.clipboard = "unnamedplus"               -- allows neovim to access the system clipboard
vim.opt.cursorline = true                       -- highlight the current line
vim.opt.number = true                           -- set numbered lines
vim.opt.mouse = "a"                             -- allow the mouse to be used in neovim
vim.opt.ignorecase = true                       -- ignore case in search patterns
vim.api.nvim_set_keymap('i', 'jj', '<ESC>', { noremap = true, silent = true })
vim.opt.autoindent=true
vim.opt.smartindent=true
vim.opt.showmatch=true
vim.opt.modifiable=true



