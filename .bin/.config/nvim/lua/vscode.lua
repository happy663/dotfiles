local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "<leader>/", "<Plug>NERDCommenterToggle", opts)
map("v", "<leader>/", "<Plug>NERDCommenterToggle", opts)
map("n", "<Leader>f", "<CMD>FuzzyMotion<CR>", opts)
