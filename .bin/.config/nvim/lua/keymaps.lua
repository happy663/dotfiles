-- keymaps.lua
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Normal mode keymaps
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-l>", "<C-w>l", opts)
--map("n", "<C-j>", "<C-w>j", opts)
--map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-b>", ":NvimTreeToggle<CR>", opts)

-- easy-motion
map("n", "<Leader><Leader>", "<CMD>Lazy<CR>", opts)

-- fuzzy-motion
map("n", "<Leader>f", "<CMD>FuzzyMotion<CR>", opts)

map("n", "<C-p>", "<CMD>Telescope recent-files recent_files<CR>", opts)
-- ファイルを検索する
--map("n", "<C-p>", "<cmd>lua require('telescope.builtin').find_files()<CR>", opts)
-- ファイル内をgrep検索する
map("n", "<C-g>", '<cmd>lua require("telescope.builtin").live_grep()<CR>', opts)
-- カーソルまたは選択範囲のgrep検索
map("n", "<Leader>*", '<cmd>lua require("telescope.builtin").grep_string()<CR>', opts)
-- 履歴表示
map("n", "<Leader>h", '<cmd>lua require("telescope.builtin").search_history()<CR>', opts)
-- Gitブランチを切り替える
map("n", "<Leader>b", '<cmd>lua require("telescope.builtin").git_branches()<CR>', opts)
-- git statusを表示
--map("n", "<Leader>gs", '<cmd>lua require("telescope.builtin").git_status()<CR>', opts)

map("n", "<Leader>[", "<Plug>(jumpcursor-jump)", opts)
map("n", "<leader>/", "<Plug>NERDCommenterToggle", opts)
map("n", "x", '"_x', opts)
map("n", "-", "<CMD>split<CR>", opts)
map("n", "|", "<CMD>vsplit<CR>", opts)
map("n", "<leader>wl", "<CMD>BufferLineCloseRight<CR>", opts)
map("n", "<S-k>", "<CMD>BufferLineCycleNext<CR>", opts)
map("n", "<S-j>", "<CMD>BufferLineCyclePrev<CR>", opts)
map("n", "<C-f>", "<CMD>lua vim.lsp.buf.format({ async = false })<CR><CMD>w<CR>", opts)

map("n", "<leader>w", "<CMD>w<CR>", opts)
map("n", "<leader>wq", "<CMD>wq<CR>", opts)
map("n", "<leader>q", "<CMD>q!<CR>", opts)

-- Insert mode keymaps
map("i", "jj", "<Esc>", opts)
map("i", "<C-f>", "<Right>", opts)
map("i", "<C-b>", "<Left>", opts)

-- Visual mode keymaps
map("v", "<leader>/", "<Plug>NERDCommenterToggle", opts)

-- terminal mode
-- escapeでnormal modeに戻る
map("t", "<esc>", [[<C-\><C-n>]], opts)
map("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
map("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
map("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*lazygit*",
  callback = function()
    -- normal modeに戻らずlazygitのesc機能を使うための設定
    vim.api.nvim_buf_set_keymap(0, "t", "<C-n>", "<Down>", opts)
    vim.api.nvim_buf_set_keymap(0, "t", "<C-p>", "<Up>", opts)
    vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<esc>", opts)
  end,
})

-- 定義にジャンプする前に縦分割を行い、そのウィンドウで定義を開く関数
function goto_definition_vsplit()
  vim.cmd("vsplit") -- 縦分割コマン
  vim.cmd("tag") -- タグジャンプコマンド
end

-- カスタムコマンドとして設定
map("n", "<C-}>", "<cmd>lua goto_definition_vsplit()<CR>", { noremap = true, silent = true })

map("n", "<Leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

map("n", "<Leader>g", "<cmd>LazyGit<CR>", opts)
map("n", "<Leader>l", "<cmd>LazyGit<CR>", opts)
map("i", "っj", "<esc>", opts)
map("n", "<Leader>tf", "<CMD>Telescope frecency<CR>", opts)
map("n", "<Leader>tr", "<CMD>Telescope resume<CR>", opts)
map("n", "<Leader>tt", "<CMD>Telescope pickers<CR>", opts)

-- windows用
-- windowsではctrl+hをbackspaceに当てている
-- 他環境と同じ動きになるように調整
map("n", "<BS>", "<C-w>h", opts)

map("n", "<Leader>mn", "<CMD>MemoNew<CR>", opts)
map("n", "<Leader>ml", "<CMD>Telescope memo list<CR>", opts)
map("n", "<Leader>mg", "<CMD>Telescope memo live_grep<CR>", opts)

map("n", "<CR>", "A<Return><Esc>k", opts)

-- 矢印キーを無効化
map("n", "<Up>", "<Nop>", opts)
map("n", "<Down>", "<Nop>", opts)
map("n", "<Left>", "<Nop>", opts)
map("n", "<Right>", "<Nop>", opts)

map("n", "gp", '"+p', opts)
map("n", "gP", '"+P', opts)

-- mason
map("n", "<Leader>ma", ":Mason<CR>", opts)
