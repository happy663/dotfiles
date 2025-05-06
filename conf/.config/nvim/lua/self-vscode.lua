vim.o.timeout = true
vim.o.timeoutlen = 200 -- タイムアウトを300msに設定 (デフォルトは1000ms)

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "<leader>/", "gcc", opts)
map("v", "<leader>/", "gcc", opts)
map("n", "<Leader>f", "<CMD>HopWord<CR>", opts)
map("n", "gp", '"*p', opts)
map("n", "gP", '"*P', opts)
map("n", "<CR>", "A<Return><Esc>k", opts)

local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" and vim.v.event.regname == "" then
      vim.fn.setreg("*", vim.fn.getreg('"'))
      vim.fn.setreg("+", vim.fn.getreg('"'))
    end
  end,
})

vim.keymap.set("n", "<leader>", function()
  vim.fn["VSCodeCall"]("whichkey.show")
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>l", function()
  vim.fn["VSCodeCall"]("lazygit-vscode.toggle")
end, { noremap = true, silent = true })
--
vim.keymap.set("n", "<leader><leader>", function()
  vim.fn["VSCodeCall"]("workbench.action.showCommands")
end, { noremap = true, silent = true })
