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

-- windows用
-- windowsではctrl+hをbackspaceに当てている
-- 他環境と同じ動きになるように調整
map("n", "<BS>", "<C-w>h", opts)

map("n", "<Leader>mn", "<CMD>MemoNew<CR>", opts)

-- 矢印キーを無効化
map("n", "<Up>", "<Nop>", opts)
map("n", "<Down>", "<Nop>", opts)
map("n", "<Left>", "<Nop>", opts)
map("n", "<Right>", "<Nop>", opts)

map("n", "gp", '"+p', opts)
map("n", "gP", '"+P', opts)

-- mason
map("n", "<Leader>ma", ":Mason<CR>", opts)

vim.cmd([[
  cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ':s' ? [getchar(), ''][1] .. "%s///g<Left><Left>" : 's'
]])

vim.api.nvim_create_user_command("Help", function(command)
  local current_win_width = vim.api.nvim_win_get_width(0)
  local success, msg = pcall(vim.cmd, "vertical help " .. command.args .. " | vertical" .. current_win_width)
  if not success then
    vim.api.nvim_err_writeln(msg)
  end
end, { nargs = 1, complete = "help" })
vim.api.nvim_set_keymap("n", "<Leader>je", ":Help ", opts)

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

-- diagnostic_to_qf - 条件付き読み込み
local ok, diag_qf = pcall(require, "diagnostic_to_qf")
if ok then
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
end

-- leader wqで保存して終了
map("n", "<leader>qw", "<CMD>wq<CR>", opts)
map("n", "<leader>qq", "<CMD>q<CR>", opts)
map("n", "<leader>qa", "<CMD>qa<CR>", opts)

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

-- normalモードの時に位置がずれるので調整
vim.keymap.set("i", "<C-v>", '<C-o>"+P', { noremap = true, silent = true, desc = "Paste from clipboard" })

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

-- ターミナル出力テキストオブジェクト（it/at）
do
  local function is_prompt_line(line)
    return line:match("^❯") ~= nil
  end

  local function is_info_line(line)
    return line:match("│") ~= nil
  end

  local function select_terminal_output(inner)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    -- カーソル位置から上方向に ❯ 行を探す
    local cmd_row = nil
    for i = row, 1, -1 do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if is_prompt_line(line) then
        cmd_row = i
        break
      end
    end
    if not cmd_row then
      return
    end

    -- コマンド行の下から、次のプロンプト境界を探す
    local end_row = line_count
    for i = cmd_row + 1, line_count do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if is_info_line(line) or is_prompt_line(line) then
        end_row = i - 1
        break
      end
    end

    -- 末尾の空行を除外
    while end_row > cmd_row do
      local line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, false)[1]
      if line:match("^%s*$") then
        end_row = end_row - 1
      else
        break
      end
    end

    if inner then
      -- it: 出力のみ（コマンド行の次の行から）
      local start = cmd_row + 1
      if start > end_row then
        return
      end
      vim.api.nvim_win_set_cursor(0, { start, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
    else
      -- at: コマンド行 + 出力
      vim.api.nvim_win_set_cursor(0, { cmd_row, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
    end
  end

  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
      local buf_opts = { buffer = ev.buf, silent = true }
      vim.keymap.set({ "o", "x" }, "it", function()
        select_terminal_output(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "inner terminal output" }))
      vim.keymap.set({ "o", "x" }, "at", function()
        select_terminal_output(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "around terminal output" }))
    end,
  })
end

-- Claude Code会話テキストオブジェクト（ic/ac, iC/aC）
do
  local function is_claude_block_line(line)
    return line:match("^⏺") ~= nil
  end

  local function is_user_prompt_line(line)
    return line:match("^❯") ~= nil
  end

  -- ic/ac: 1つの⏺応答ブロックを選択
  local function select_claude_block(inner)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    -- カーソル位置から上方向に ⏺ 行を探す
    local block_start = nil
    for i = row, 1, -1 do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if is_claude_block_line(line) then
        block_start = i
        break
      end
      -- ❯行に到達したら、このカーソル位置は⏺ブロック内ではない
      if is_user_prompt_line(line) and i < row then
        return
      end
    end
    if not block_start then
      return
    end

    -- ブロック開始行の下から、次の⏺または❯を探す（ブロック終端）
    local end_row = line_count
    for i = block_start + 1, line_count do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if is_claude_block_line(line) or is_user_prompt_line(line) then
        end_row = i - 1
        break
      end
    end

    -- 末尾の空行を除外
    while end_row > block_start do
      local line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, false)[1]
      if line:match("^%s*$") then
        end_row = end_row - 1
      else
        break
      end
    end

    if inner then
      local start = block_start + 1
      if start > end_row then
        return
      end
      vim.api.nvim_win_set_cursor(0, { start, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
    else
      vim.api.nvim_win_set_cursor(0, { block_start, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
    end
  end

  -- iC/aC: 1ターン全体（❯入力 + 全応答）を選択
  local function select_claude_turn(inner)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    -- カーソル位置から上方向に ❯ 行を探す
    local turn_start = nil
    for i = row, 1, -1 do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if is_user_prompt_line(line) then
        turn_start = i
        break
      end
    end
    if not turn_start then
      return
    end

    -- ターン開始行の下から、次の❯を探す（ターン終端）
    local end_row = line_count
    for i = turn_start + 1, line_count do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if is_user_prompt_line(line) then
        end_row = i - 1
        break
      end
    end

    -- 末尾の空行を除外
    while end_row > turn_start do
      local line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, false)[1]
      if line:match("^%s*$") then
        end_row = end_row - 1
      else
        break
      end
    end

    if inner then
      local start = turn_start + 1
      if start > end_row then
        return
      end
      vim.api.nvim_win_set_cursor(0, { start, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
    else
      vim.api.nvim_win_set_cursor(0, { turn_start, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { end_row, 0 })
    end
  end

  -- ]c / [c: 次/前の⏺ブロックにジャンプ
  -- ]C / [C: 次/前の❯ターンにジャンプ
  local function jump_claude_block(forward)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    if forward then
      for i = row + 1, line_count do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if is_claude_block_line(line) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    else
      for i = row - 1, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if is_claude_block_line(line) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    end
  end

  local function jump_claude_turn(forward)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local line_count = vim.api.nvim_buf_line_count(0)

    if forward then
      for i = row + 1, line_count do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if is_user_prompt_line(line) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    else
      for i = row - 1, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if is_user_prompt_line(line) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    end
  end

  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
      local buf_opts = { buffer = ev.buf, silent = true }
      -- テキストオブジェクト
      vim.keymap.set({ "o", "x" }, "ic", function()
        select_claude_block(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "inner claude block" }))
      vim.keymap.set({ "o", "x" }, "ac", function()
        select_claude_block(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "around claude block" }))
      vim.keymap.set({ "o", "x" }, "iC", function()
        select_claude_turn(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "inner claude turn" }))
      vim.keymap.set({ "o", "x" }, "aC", function()
        select_claude_turn(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "around claude turn" }))
      -- ジャンプ
      vim.keymap.set("n", "]c", function()
        jump_claude_block(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "next claude block" }))
      vim.keymap.set("n", "[c", function()
        jump_claude_block(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "prev claude block" }))
      vim.keymap.set("n", "}", function()
        jump_claude_turn(true)
      end, vim.tbl_extend("force", buf_opts, { desc = "next claude turn" }))
      vim.keymap.set("n", "{", function()
        jump_claude_turn(false)
      end, vim.tbl_extend("force", buf_opts, { desc = "prev claude turn" }))
    end,
  })
end

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
  if summary == nil or summary == "" then
    summary = "詳細"
  end

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

-- <C-d> の再マッピング
vim.api.nvim_set_keymap("n", "<C-d>", "<Cmd>keepjumps normal! <C-d><CR>", { noremap = true, silent = true })

-- <C-u> の再マッピング
vim.api.nvim_set_keymap("n", "<C-u>", "<Cmd>keepjumps normal! <C-u><CR>", { noremap = true, silent = true })

-- { の再マッピング
vim.api.nvim_set_keymap("n", "{", "<Cmd>keepjumps normal! {<CR>", { noremap = true, silent = true })

-- } の再マッピング
vim.api.nvim_set_keymap("n", "}", "<Cmd>keepjumps normal! }<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "zz", "za", { noremap = true, silent = true, desc = "Fold toggle" })

vim.keymap.set("n", "<Tab>", "za", { noremap = true, silent = true, desc = "Fold toggle" })
vim.keymap.set("n", "<C-i>", "<C-i>", { noremap = true, silent = true, desc = "Fold toggle" })

vim.keymap.set("n", "<S-Tab>", "zc", { noremap = true, silent = true, desc = "Fold close" })
vim.keymap.set("n", "<leader><Tab>", "zR", { noremap = true, silent = true, desc = "Fold open all" })
vim.keymap.set("n", "<leader><S-Tab>", "zM", { noremap = true, silent = true, desc = "Fold close all" })

vim.keymap.set("n", "<Leader>tih", function()
  local time = os.date("%Y-%m-%d (%a) %H:%M")
  vim.api.nvim_put({ time }, "c", true, true)
end, { desc = "Insert current time with weekday" })

vim.cmd('iabbrev ** <C-r>=strftime("%Y-%m-%d")<C-r>')

-- コマンドラインで空行削除コマンドを展開
vim.cmd([[
  cnoreabbrev gd g/^$/d
]])

vim.keymap.set("n", "gf", function()
  local cfile = vim.fn.expand("<cfile>")
  if vim.fn.filereadable(cfile) == 1 then
    print("Opening file: " .. cfile)
    vim.cmd("edit " .. cfile)
  else
    if cfile:match("^https?://github.com") then
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

vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*/Library/Caches/ovim/*",
  callback = function()
    vim.keymap.set("i", "<C-CR>", function()
      vim.cmd("wq")
    end, { buffer = true, silent = true })
    vim.keymap.set("n", "<C-CR>", ":wq<CR>", { buffer = true, silent = true })
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "skkeleton-enable-post",
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if vim.bo.buftype == "terminal" and string.match(bufname, "codex") then
      vim.keymap.set(
        "t",
        "<C-CR>",
        [[<C-\><C-n>A<CR><Esc>]],
        { buffer = true, noremap = true, silent = true, nowait = true }
      )
    end
  end,
})

-- editprompt integration
if vim.env.EDITPROMPT == "1" then
  -- エディタを閉じずに送信（自動Enter押下 + フォーカス戻る）
  vim.keymap.set("n", "<C-CR>", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")
    local escaped_content = vim.fn.shellescape(content)
    vim.fn.system("editprompt input --auto-send -- " .. escaped_content)
  end, { noremap = true, silent = true, desc = "Send to target pane with auto-send" })

  -- エディタを閉じずに送信（フォーカスは対象ペインに移動）
  vim.keymap.set("n", "<leader>es", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")
    local escaped_content = vim.fn.shellescape(content)
    vim.fn.system("editprompt input -- " .. escaped_content)
  end, { noremap = true, silent = true, desc = "Send to target pane" })

  -- 収集した引用を取得
  vim.keymap.set("n", "<leader>ed", function()
    vim.fn.system("editprompt dump")
    vim.cmd('normal! "+p')
  end, { noremap = true, silent = true, desc = "Dump collected quotes" })
end

vim.keymap.set("n", "<leader>ups", function()
  vim.cmd([[
		:profile start /tmp/nvim-profile.log
		:profile func *
		:profile file *
	]])
end, { desc = "Profile Start" })

vim.keymap.set("n", "<leader>upe", function()
  vim.cmd([[
		:profile stop
		:e /tmp/nvim-profile.log
	]])
end, { desc = "Profile End" })

vim.keymap.set("t", "<ESC>", "<ESC>", { desc = "description", noremap = true, silent = true })
