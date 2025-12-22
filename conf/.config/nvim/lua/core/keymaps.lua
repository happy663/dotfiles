-- keymaps.lua
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Normal mode keymaps
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-l>", "<C-w>l", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)

-- easy-motion
--
map("n", "<Leader><Leader>", "<CMD>Lazy<CR>", opts)

map("n", "<leader>/", "gcc", { noremap = false, silent = true })
map("n", "x", '"_x', opts)
-- map("n", "-", "<CMD>split<CR>", opts)
map("n", "|", "<CMD>vsplit<CR>", opts)
map("n", "<C-f>", "<CMD>lua vim.lsp.buf.format({ async = false })<CR><CMD>w<CR>", opts)

-- Insert mode keymaps
map("i", "jj", "<Esc>", opts)
map("i", "<C-f>", "<Right>", opts)
map("i", "<C-b>", "<Left>", opts)

-- Visual mode keymaps
map("v", "<leader>/", "gcc", { noremap = false, silent = true })
-- terminal mode
-- escapeでnormal modeに戻る
map("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
map("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
map("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)

-- 定義にジャンプする前に縦分割を行い、そのウィンドウで定義を開く関数
_G.goto_definition_vsplit = function()
  print("goto_definition_vsplit")
  vim.cmd("vsplit") -- 縦分割コマン
  vim.cmd("tag") -- タグジャンプコマンド
end

-- カスタムコマンドとして設定
map("n", "<leader>]", "<cmd>lua goto_definition_vsplit()<CR>", { noremap = true, silent = true })

map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", opts)
vim.keymap.set("n", "<Leader>tr", function()
  vim.cmd("Telescope resume")
end, opts)
vim.keymap.set("n", "<Leader>tt", function()
  vim.cmd("Telescope pickers")
end, opts)
map("n", "<Leader>tq", "<CMD>Telescope quickfix<CR>", opts)

-- windows用
-- windowsではctrl+hをbackspaceに当てている
-- 他環境と同じ動きになるように調整
map("n", "<BS>", "<C-w>h", opts)

map("n", "<Leader>mn", "<CMD>MemoNew<CR>", opts)
map("n", "<Leader>ml", "<CMD>Telescope memo list<CR>", opts)
map("n", "<Leader>mg", "<CMD>Telescope memo live_grep<CR>", opts)

-- 矢印キーを無効化
map("n", "<Up>", "<Nop>", opts)
map("n", "<Down>", "<Nop>", opts)
map("n", "<Left>", "<Nop>", opts)
map("n", "<Right>", "<Nop>", opts)

map("n", "gp", '"+p', opts)
map("n", "gP", '"+P', opts)

-- mason
map("n", "<Leader>ma", ":Mason<CR>", opts)

map("i", "<C-J>", "<Plug>(skkeleton-enable)", opts)
map("c", "<C-J>", "<Plug>(skkeleton-enable)", opts)
map("t", "<C-J>", "<Plug>(skkeleton-enable)", opts)

map("n", "<Leader>cr", "<CMD>RunCode<CR>", opts)

vim.cmd([[
  cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ':s' ? [getchar(), ''][1] .. "%s///g<Left><Left>" : 's'
]])

vim.g.highlight_on = true
function Toggle_highlight()
  if vim.g.highlight_on then
    -- ハイライトがオンの場合、オフにする
    vim.cmd("nohlsearch")
    vim.cmd("HlSearchLensDisable")
    vim.g.highlight_on = false
  else
    -- ハイライトがオフの場合、オンにする
    vim.cmd("set hlsearch")
    vim.cmd("HlSearchLensEnable")
    vim.g.highlight_on = true
  end
end

vim.api.nvim_create_autocmd("CmdlineEnter", {
  pattern = { "/" },
  callback = function()
    vim.g.highlight_on = true
  end,
})

map("n", "<ESC><ESC>", "<cmd>lua Toggle_highlight()<CR>", opts)
map("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>", opts)

map("n", "<Leader>h", "<CMD>FuzzyMotion<CR>", opts)
vim.cmd("let g:fuzzy_motion_matchers = ['kensaku', 'fzf']")

vim.api.nvim_create_user_command("Help", function(command)
  local current_win_width = vim.api.nvim_win_get_width(0)
  local success, msg = pcall(vim.cmd, "vertical help " .. command.args .. " | vertical" .. current_win_width)
  if not success then
    vim.api.nvim_err_writeln(msg)
  end
end, { nargs = 1, complete = "help" })
vim.api.nvim_set_keymap("n", "<Leader>je", ":Help ", opts)

vim.g.gyazo_insert_markdown_url = 1
vim.api.nvim_set_keymap("n", "<leader>gy", "<Plug>(gyazo-upload)", { noremap = false, silent = true })

vim.api.nvim_set_keymap("n", "<CR>", "A<Return><Esc>", { noremap = true, silent = true })

-- クイックフィックスウィンドウでマッピングを上書きする
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<CR>", { noremap = true, silent = true, nowait = true })
  end,
})

-- Lazyプラグインマネージャーのウィンドウでのキーマップを無効化
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lazy",
  callback = function()
    -- C-h, C-j, C-k, C-lのキーマップを無効化
    vim.api.nvim_buf_set_keymap(0, "n", "<C-h>", "", { noremap = true, silent = true, nowait = true })
    vim.api.nvim_buf_set_keymap(0, "n", "<C-j>", "", { noremap = true, silent = true, nowait = true })
    vim.api.nvim_buf_set_keymap(0, "n", "<C-k>", "", { noremap = true, silent = true, nowait = true })
    vim.api.nvim_buf_set_keymap(0, "n", "<C-l>", "", { noremap = true, silent = true, nowait = true })
  end,
})

_G.toggle_cwindow = function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      qf_exists = true
      break
    end
  end
  if qf_exists then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end

map("n", "<leader>cw", "<cmd>lua toggle_cwindow()<CR>", opts)

map("n", "<M-;>", "<CMD>cprev<CR>", opts)
map("n", "<M-'>", "<CMD>cnext<CR>", opts)

-- init.luaまたは適切な設定ファイルでキーマッピングを設定
local diag_qf = require("diagnostic_to_qf")

-- すべての診断情報をQuickfixリストに送る
vim.api.nvim_set_keymap(
  "n",
  "<leader>dq",
  ':lua require("diagnostic_to_qf").diagnostics_to_qf()<CR>',
  { noremap = true, silent = true }
)

-- 現在のバッファの診断情報をQuickfixリストに送る
vim.api.nvim_set_keymap(
  "n",
  "<leader>db",
  ':lua require("diagnostic_to_qf").buffer_diagnostics_to_qf()<CR>',
  { noremap = true, silent = true }
)

-- leader wqで保存して終了
map("n", "<leader>qw", "<CMD>wq<CR>", opts)
map("n", "<leader>qq", "<CMD>q<CR>", opts)
map("n", "<leader>qa", "<CMD>qa<CR>", opts)

vim.api.nvim_set_keymap(
  "n",
  "n",
  [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
  opts
)
vim.api.nvim_set_keymap(
  "n",
  "N",
  [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
  opts
)

vim.keymap.set("n", "<leader>yy", function()
  vim.cmd("normal! ggVGy")
end, { noremap = true, silent = true, desc = "copy all sentence from current_file" })

vim.keymap.set("n", "<leader>dd", function()
  vim.cmd("normal! ggVGd")
end, { noremap = true, silent = true, desc = "delete all sentence from current_file" })

vim.keymap.set("n", "q", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>mq", "q", { noremap = true, silent = true })

-- 相対パスをコピー
vim.keymap.set(
  "n",
  "<leader>pc",
  "<Cmd>let @+ = expand('%')<CR>",
  { noremap = true, silent = true, desc = "Copy relative path" }
)

-- 絶対パスをコピー
vim.keymap.set(
  "n",
  "<leader>pa",
  "<Cmd>let @+ = expand('%:p')<CR>",
  { noremap = true, silent = true, desc = "Copy absolute path" }
)

vim.keymap.set("i", "<C-v>", '<C-o>"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })

-- map("t", "<Esc>", "<Esc>", opts)
-- map("t", "<C-w>", "<C-\\><C-n><C-w>", opts)
-- map("t", "<esc>", [[<C-\><C-n>]], opts)
-- lazygitプロセスが実行中でない場合のみjjキーマップを有効にする
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if not string.match(buf_name, "lazygit") then
      vim.keymap.set("t", "jj", [[<C-\><C-n>]], { buffer = true, noremap = true, silent = true })
    end
  end,
})

-- vim.keymap.set("n", "<leader>olh", ":Octo issue list assignee=happy663<CR>", {
--   noremap = true,
--   silent = true,
--   desc = "Open Octo issues assigned to happy663",
-- })
--
-- vim.keymap.set("n", "<leader>oll", ":Octo issue list<CR>", {
--   noremap = true,
--   silent = true,
--   desc = "Open Octo issues assigned to happy663",
-- })

local function get_clipboard_lines()
  local clipboard_content = vim.fn.getreg("+")
  local code_lines = vim.split(clipboard_content, "\n", { plain = true })

  if code_lines[#code_lines] == "" then
    table.remove(code_lines, #code_lines)
  end

  return code_lines
end

vim.keymap.set("n", "<Leader>py", function()
  local code_line = get_clipboard_lines()

  table.insert(code_line, 1, "```")
  table.insert(code_line, "```")

  vim.api.nvim_put(code_line, "l", true, false)
  vim.cmd("normal! k")
end, {
  noremap = true,
  silent = true,
  desc = "Paste clipboard content as a code block",
})

vim.keymap.set("n", "<Leader>pd", function()
  local code_lines = get_clipboard_lines()
  local summary = vim.fn.input("Summary: ") or "詳細"

  local result = {
    "<details>",
    "<summary>" .. summary .. "</summary>",
    "",
  }
  vim.list_extend(result, code_lines)
  table.insert(result, "</details>")

  vim.api.nvim_put(result, "l", true, false)
  vim.cmd("normal! k")
end, {
  noremap = true,
  silent = true,
  desc = "Paste clipboard content inside HTML <details> tag",
})

vim.keymap.set("n", "<Leader>ps", function()
  local clipboard_content = vim.fn.getreg("+")
  local code_lines = vim.split(clipboard_content, "\n", { plain = true })
  local summary = vim.fn.input("Summary: ") or "詳細"

  local result = {
    "<details>",
    "<summary>" .. summary .. "</summary>",
    "", -- 空行
    "```",
  }

  vim.list_extend(result, code_lines)
  table.insert(result, "```")
  table.insert(result, "</details>")

  vim.api.nvim_put(result, "l", true, false)
end, {
  noremap = true,
  silent = true,
  desc = "Paste clipboard content as a code block inside HTML <details> tag",
})

-- <C-d> の再マッピング
vim.api.nvim_set_keymap("n", "<C-d>", "<Cmd>keepjumps normal! <C-d><CR>", { noremap = true, silent = true })

-- <C-u> の再マッピング
vim.api.nvim_set_keymap("n", "<C-u>", "<Cmd>keepjumps normal! <C-u><CR>", { noremap = true, silent = true })

-- { の再マッピング
vim.api.nvim_set_keymap("n", "{", "<Cmd>keepjumps normal! {<CR>", { noremap = true, silent = true })

-- } の再マッピング
vim.api.nvim_set_keymap("n", "}", "<Cmd>keepjumps normal! }<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<Tab>", "zo", { noremap = true, silent = true, desc = "Fold open" })
vim.keymap.set("n", "<S-Tab>", "zc", { noremap = true, silent = true, desc = "Fold close" })
vim.keymap.set("n", "<leader><Tab>", "zR", { noremap = true, silent = true, desc = "Fold open all" })
vim.keymap.set("n", "<leader><S-Tab>", "zM", { noremap = true, silent = true, desc = "Fold close all" })

vim.keymap.set("n", "<Leader>tih", function()
  local time = os.date("%Y-%m-%d (%a) %H:%M")
  vim.api.nvim_put({ time }, "c", true, true)
end, { desc = "Insert current time with weekday" })

vim.cmd('iabbrev ** <C-r>=strftime("%Y-%m-%d")<C-r>')

vim.keymap.set("n", "gf", function()
  local cfile = vim.fn.expand("<cfile>")
  if vim.fn.filereadable(cfile) == 1 then
    print("Opening file: " .. cfile)
    vim.cmd("edit " .. cfile)
  else
    if cfile:match("^https?://github.com") then
      -- https://github.com/voyagegroup/zgok-db/blob/f0049cb054dc0faa90a3f76cbbd95858c7ffcdcf/contrib/local_env/zgok/Dockerfile#L6-L9
      local home_dir = vim.fn.getenv("HOME")
      local organization = string.match(cfile, "https://github%.com/([^/]+)/")
      local repository_name = string.match(cfile, "https://github%.com/[^/]+/([^/]+)/")
      local local_path = cfile
        :gsub(
          "https://github%.com/[^/]+/[^/]+/[^/]+/[^/]+",
          home_dir .. "/src/github.com/" .. organization .. "/" .. repository_name
        )
        :gsub("#.*", "")
      print(local_path)
      local line = cfile:match("#L(%d+)-?")
      if line then
        print(local_path .. ":" .. line)
        vim.cmd("edit " .. local_path)
        vim.cmd(line)
      else
        vim.cmd("edit " .. local_path)
      end
    else
      print("File not found: " .. cfile)
    end
  end
end)
