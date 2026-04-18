-- claude_input.lua
-- Claude Code向け入力バッファの作成と送信を管理するモジュール

local M = {}
M.defaults = {
  target_pattern = "claude",
}

local function is_valid_buf(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local function notify(msg, level)
  vim.notify("[claude_input] " .. msg, level or vim.log.levels.INFO)
end

local function get_draft_bufnr()
  if is_valid_buf(vim.t.claude_input_bufnr) then
    return vim.t.claude_input_bufnr
  end
  return nil
end

local function trim_trailing_empty_lines(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  return lines
end

local function focus_existing_draft(bufnr)
  local windows = vim.fn.win_findbuf(bufnr)
  for _, winid in ipairs(windows) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("startinsert")
      return true
    end
  end
  return false
end

local function resolve_target_terminal_bufnr(target_pattern)
  if is_valid_buf(vim.t.claude_terminal_bufnr) and vim.bo[vim.t.claude_terminal_bufnr].buftype == "terminal" then
    return vim.t.claude_terminal_bufnr
  end

  local bridge_ok, terminal_bridge = pcall(require, "terminal_bridge")
  if not bridge_ok then
    return nil
  end

  local terminal = terminal_bridge.find_terminal_by_pattern(target_pattern, false)
  if terminal and is_valid_buf(terminal.bufnr) then
    return terminal.bufnr
  end

  return nil
end

local function ensure_buffer_keymaps(bufnr)
  vim.keymap.set("n", "<C-CR>", "<Cmd>ClaudeDraftSend<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Send draft to Claude",
  })
  vim.keymap.set("i", "<C-CR>", "<Esc><Cmd>ClaudeDraftSend<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Send draft to Claude",
  })
  vim.keymap.set("n", "<leader>ic", "<Cmd>ClaudeDraftClear<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Clear Claude draft buffer",
  })
  vim.keymap.set("n", "<leader>is", "<Cmd>ClaudeDraftSend<CR>", {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Send Claude draft buffer",
  })
end

function M.focus_or_open(opts)
  opts = opts or {}

  local draft_bufnr = get_draft_bufnr()
  if draft_bufnr then
    if focus_existing_draft(draft_bufnr) then
      return true, "Focused existing draft buffer"
    end
    vim.cmd("belowright split")
    if type(opts.draft_height) == "number" and opts.draft_height > 0 then
      vim.cmd("resize " .. tostring(opts.draft_height))
    end
    vim.api.nvim_win_set_buf(0, draft_bufnr)
    vim.wo.winfixheight = true
    vim.cmd("startinsert")
    return true, "Opened existing draft buffer"
  end

  local target_pattern = opts.target_pattern or vim.t.claude_input_target_pattern or M.defaults.target_pattern
  local terminal_bufnr = opts.claude_bufnr
  if not is_valid_buf(terminal_bufnr) then
    terminal_bufnr = resolve_target_terminal_bufnr(target_pattern)
  end
  if not is_valid_buf(terminal_bufnr) then
    return false, "Target terminal not found for draft buffer"
  end

  vim.cmd("belowright split")
  if type(opts.draft_height) == "number" and opts.draft_height > 0 then
    vim.cmd("resize " .. tostring(opts.draft_height))
  end
  M.open_input_buffer({
    claude_bufnr = terminal_bufnr,
    target_pattern = target_pattern,
  })
  return true, "Opened draft buffer"
end

function M.open_input_buffer(opts)
  opts = opts or {}

  local bufnr = get_draft_bufnr()
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "[Claude Input]")
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "markdown"
    vim.bo[bufnr].modifiable = true
    ensure_buffer_keymaps(bufnr)
    vim.b[bufnr].claude_input = true
  end

  vim.t.claude_input_bufnr = bufnr
  if opts.claude_bufnr and is_valid_buf(opts.claude_bufnr) then
    vim.t.claude_terminal_bufnr = opts.claude_bufnr
  end
  if type(opts.target_pattern) == "string" and opts.target_pattern ~= "" then
    vim.t.claude_input_target_pattern = opts.target_pattern
  end

  vim.api.nvim_win_set_buf(0, bufnr)
  vim.wo.winfixheight = true

  -- 補完ポップアップが下に表示されるよう候補数を制限
  -- local cmp_ok, cmp = pcall(require, "cmp")
  -- if cmp_ok then
  --   cmp.setup.buffer({
  --     performance = {
  --       max_view_entries = 5,
  --     },
  --   })
  -- end

  vim.cmd("startinsert")

  return bufnr
end

function M.clear_draft()
  local bufnr = get_draft_bufnr()
  if not bufnr then
    return false, "Claude draft buffer not found"
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  return true, "Claude draft buffer cleared"
end

function M.send_draft()
  local bridge_ok, terminal_bridge = pcall(require, "terminal_bridge")
  if not bridge_ok then
    local message = "terminal_bridge module not found"
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  local draft_bufnr = get_draft_bufnr()
  if not draft_bufnr then
    local message = "Claude draft buffer not found"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local lines = vim.api.nvim_buf_get_lines(draft_bufnr, 0, -1, false)
  trim_trailing_empty_lines(lines)

  local content = table.concat(lines, "\n")
  if content == "" then
    local message = "Draft is empty"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local target_index
  local claude_bufnr = vim.t.claude_terminal_bufnr
  local target_pattern = vim.t.claude_input_target_pattern or M.defaults.target_pattern
  if is_valid_buf(claude_bufnr) then
    local terminals = terminal_bridge.get_all_terminals()
    for index, term in ipairs(terminals) do
      if term.bufnr == claude_bufnr then
        target_index = index
        break
      end
    end
  end

  local target = target_index or target_pattern
  local success, message =
    terminal_bridge.send_command(target, content, { add_newline = true, exclude_current = false })
  if not success then
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  return true, message
end

function M.quote_to_draft(lines, opts)
  opts = opts or {}

  -- 各行に "> " プレフィックスを付与
  local quoted = {}
  for _, line in ipairs(lines) do
    table.insert(quoted, "> " .. line)
  end

  -- ドラフトバッファの取得・作成
  local draft_bufnr = get_draft_bufnr()
  local need_open = draft_bufnr == nil

  if need_open then
    local success, message = M.focus_or_open({
      draft_height = opts.draft_height,
      target_pattern = opts.target_pattern,
      claude_bufnr = opts.claude_bufnr,
    })
    if not success then
      return false, message
    end
    draft_bufnr = get_draft_bufnr()
    if not draft_bufnr then
      return false, "Failed to create draft buffer"
    end
  end

  -- 既存内容の確認
  local existing = vim.api.nvim_buf_get_lines(draft_bufnr, 0, -1, false)
  local has_content = not (#existing == 0 or (#existing == 1 and existing[1] == ""))

  -- 追記する行を組み立て
  local to_append = {}
  if has_content then
    table.insert(to_append, "")
  end
  for _, q in ipairs(quoted) do
    table.insert(to_append, q)
  end
  table.insert(to_append, "")

  -- ドラフトバッファに追記
  if has_content then
    vim.api.nvim_buf_set_lines(draft_bufnr, -1, -1, false, to_append)
  else
    vim.api.nvim_buf_set_lines(draft_bufnr, 0, -1, false, to_append)
  end

  -- ドラフトバッファにフォーカスして末尾でインサートモード
  if not need_open then
    local windows = vim.fn.win_findbuf(draft_bufnr)
    for _, winid in ipairs(windows) do
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_set_current_win(winid)
        break
      end
    end
  end
  local line_count = vim.api.nvim_buf_line_count(draft_bufnr)
  vim.api.nvim_win_set_cursor(0, { line_count, 0 })
  vim.cmd("startinsert|normal! $")

  return true, "Quoted " .. #quoted .. " lines to draft"
end

return M
