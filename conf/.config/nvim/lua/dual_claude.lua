-- dual_claude.lua
-- 2つのClaude Codeターミナル + 中央寄せ入力バッファのレイアウト

local M = {}

M.config = {
  command = "claude",
  input_height = 15,
  padding_width = 15,
  draft_height = 8,
  draft_target_pattern = "claude",
}

-- ハイライトグループ定義
vim.api.nvim_set_hl(0, "DualClaudePadding", { bg = "#1a1a2e" })

local function create_padding_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  return buf
end

local function setup_padding_win(winid)
  vim.wo[winid].winfixwidth = true
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].signcolumn = "no"
  vim.wo[winid].statuscolumn = ""
  vim.wo[winid].winhighlight = "Normal:DualClaudePadding,EndOfBuffer:DualClaudePadding"
end

local function find_index(tbl, value)
  for i, v in ipairs(tbl) do
    if v == value then
      return i
    end
  end
  return nil
end

local function send_to_target(target_bufnr)
  vim.t.claude_terminal_bufnr = target_bufnr
  vim.cmd("ClaudeDraftSend")
end

local function setup_send_keymaps(input_bufnr, claude1_bufnr, claude2_bufnr)
  -- <C-CR>: claude1に送信（固定）
  vim.keymap.set({ "n", "i" }, "<C-CR>", function()
    send_to_target(claude1_bufnr)
  end, { buffer = input_bufnr, noremap = true, silent = true, desc = "Send draft to Claude 1" })

  -- <S-CR>: claude2に送信（固定）
  vim.keymap.set({ "n", "i" }, "<S-CR>", function()
    send_to_target(claude2_bufnr)
  end, { buffer = input_bufnr, noremap = true, silent = true, desc = "Send draft to Claude 2" })
end

local function setup_cycle_keymaps(bufnr)
  vim.keymap.set({ "n", "t" }, "<C-k>", function()
    M.cycle_forward()
  end, { buffer = bufnr, noremap = true, silent = true, desc = "DualClaude: cycle forward" })

  vim.keymap.set({ "n", "t" }, "<C-j>", function()
    M.cycle_backward()
  end, { buffer = bufnr, noremap = true, silent = true, desc = "DualClaude: cycle backward" })
end

function M.cycle_forward()
  if not vim.t.dual_claude_active then
    return
  end
  local cycle = {
    vim.t.dual_claude_input_winid,
    vim.t.dual_claude_claude1_winid,
    vim.t.dual_claude_claude2_winid,
  }
  local current = vim.api.nvim_get_current_win()
  local idx = find_index(cycle, current)
  if not idx then
    idx = 0
  end
  local next_idx = (idx % #cycle) + 1
  local next_win = cycle[next_idx]
  if next_win and vim.api.nvim_win_is_valid(next_win) then
    vim.api.nvim_set_current_win(next_win)
  end
end

function M.cycle_backward()
  if not vim.t.dual_claude_active then
    return
  end
  local cycle = {
    vim.t.dual_claude_input_winid,
    vim.t.dual_claude_claude1_winid,
    vim.t.dual_claude_claude2_winid,
  }
  local current = vim.api.nvim_get_current_win()
  local idx = find_index(cycle, current)
  if not idx then
    idx = 0
  end
  local prev_idx = ((idx - 2) % #cycle) + 1
  local prev_win = cycle[prev_idx]
  if prev_win and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
end

function M.open(opts)
  opts = opts or {}
  local args = opts.args or ""
  local claude_cmd = M.config.command
  if args ~= "" then
    claude_cmd = claude_cmd .. " " .. args
  end

  local claude_input_ok, claude_input = pcall(require, "claude_input")

  -- Step 1: 新タブ作成
  vim.cmd("tabnew")

  -- Step 2: claude1ターミナルを起動（上段左）
  vim.cmd("terminal " .. claude_cmd)
  local claude1_bufnr = vim.api.nvim_get_current_buf()
  local claude1_winid = vim.api.nvim_get_current_win()

  -- Step 3: 右にclaude2ターミナルを配置（上段右）
  vim.cmd("rightbelow vsplit")
  vim.cmd("terminal " .. claude_cmd)
  local claude2_bufnr = vim.api.nvim_get_current_buf()
  local claude2_winid = vim.api.nvim_get_current_win()

  -- Step 4: 画面最下部に全幅の下段ウィンドウを作成
  vim.cmd("botright split")
  vim.cmd("resize " .. tostring(M.config.input_height))
  local bottom_winid = vim.api.nvim_get_current_win()

  -- Step 5: 下段に左パディングを配置
  local left_pad_buf = create_padding_buf()
  vim.api.nvim_win_set_buf(bottom_winid, left_pad_buf)

  -- Step 6: 入力バッファを右に配置
  vim.cmd("rightbelow vsplit")
  local input_winid = vim.api.nvim_get_current_win()

  local input_bufnr
  if claude_input_ok then
    input_bufnr = claude_input.open_input_buffer({
      claude_bufnr = claude1_bufnr,
      target_pattern = M.config.draft_target_pattern,
    })
  else
    vim.notify("[DualClaude] claude_input module not found", vim.log.levels.WARN)
    vim.cmd("enew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.filetype = "markdown"
    vim.cmd("startinsert")
    input_bufnr = vim.api.nvim_get_current_buf()
  end

  -- Step 7: 右パディングを配置
  vim.cmd("rightbelow vsplit")
  local right_pad_buf = create_padding_buf()
  local right_pad_winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_pad_winid, right_pad_buf)

  -- Step 8: パディングウィンドウの設定（画面幅の1/4ずつ → 入力バッファが約半分）
  local pad_width = math.floor(vim.o.columns / 4)
  local left_pad_winid = bottom_winid
  setup_padding_win(left_pad_winid)
  vim.api.nvim_win_set_width(left_pad_winid, pad_width)

  setup_padding_win(right_pad_winid)
  vim.api.nvim_win_set_width(right_pad_winid, pad_width)

  -- Step 10: タブスコープ変数を設定
  vim.t.dual_claude_active = true
  vim.t.dual_claude_claude1_winid = claude1_winid
  vim.t.dual_claude_claude2_winid = claude2_winid
  vim.t.dual_claude_input_winid = input_winid
  vim.t.dual_claude_claude1_bufnr = claude1_bufnr
  vim.t.dual_claude_claude2_bufnr = claude2_bufnr
  vim.t.claude_terminal_bufnr = claude1_bufnr

  -- Step 11: サイクルキーマップを全バッファに設定
  local all_bufs = { claude1_bufnr, claude2_bufnr, input_bufnr, left_pad_buf, right_pad_buf }
  for _, bufnr in ipairs(all_bufs) do
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      setup_cycle_keymaps(bufnr)
    end
  end

  -- Step 12: 送信キーマップを設定（<C-CR>→claude1, <S-CR>→claude2）
  setup_send_keymaps(input_bufnr, claude1_bufnr, claude2_bufnr)

  -- 入力バッファにフォーカスを移動
  vim.api.nvim_set_current_win(input_winid)
  vim.cmd("startinsert")
end

return M
