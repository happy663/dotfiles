local config = require("agent_term.config")
local draft = require("agent_term.draft")
local state = require("agent_term.state")

local M = {}
M.dual_claude_config = config.dual_claude

local function open_fallback_input_buffer(label)
  vim.notify(label .. " claude_input module not found", vim.log.levels.WARN)
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "markdown"
  vim.cmd("startinsert")
  return vim.api.nvim_get_current_buf()
end

function M.open_codex_term(opts)
  opts = opts or {}
  local codex_cmd = opts.command or config.defaults.secondary_command
  if opts.args and opts.args ~= "" then
    codex_cmd = codex_cmd .. " " .. opts.args
  end

  vim.cmd("terminal " .. codex_cmd)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = bufnr, noremap = true, silent = true })
  return bufnr
end

function M.open_term_draft(opts)
  opts = opts or {}
  local target_bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[target_bufnr].buftype ~= "terminal" then
    vim.notify("[TermDraft] Run this command from a terminal buffer", vim.log.levels.WARN)
    return nil
  end

  vim.cmd("belowright split")
  return draft.open_input_buffer({
    claude_bufnr = target_bufnr,
    draft_height = opts.draft_height or config.defaults.draft_height,
  })
end

function M.open_claude_ai(opts)
  opts = opts or {}
  local claude_cmd = opts.command or config.defaults.primary_command
  if opts.args and opts.args ~= "" then
    claude_cmd = claude_cmd .. " " .. opts.args
  end

  vim.cmd("tabnew")
  vim.cmd("terminal " .. claude_cmd)
  local claude_bufnr = vim.api.nvim_get_current_buf()
  state.set_target_terminal_bufnr(claude_bufnr)

  vim.cmd("belowright split")
  return draft.open_input_buffer({
    claude_bufnr = claude_bufnr,
    target_pattern = opts.target_pattern or config.defaults.draft_target_pattern,
    draft_height = opts.draft_height or config.defaults.claude_ai_draft_height,
  })
end

function M.open_dual_ai(opts)
  opts = opts or {}
  if opts.open_in_new_tab ~= false and config.defaults.open_in_new_tab then
    vim.cmd("tabnew")
  end

  vim.cmd("terminal " .. (opts.primary_command or config.defaults.primary_command))
  local claude_bufnr = vim.api.nvim_get_current_buf()
  state.set_target_terminal_bufnr(claude_bufnr)

  vim.cmd("vsplit")
  vim.cmd("terminal " .. (opts.secondary_command or config.defaults.secondary_command))
  local codex_bufnr = vim.api.nvim_get_current_buf()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = codex_bufnr, noremap = true, silent = true })

  vim.cmd("wincmd h")
  vim.cmd("belowright split")

  return draft.open_input_buffer({
    claude_bufnr = claude_bufnr,
    target_pattern = opts.target_pattern or config.defaults.draft_target_pattern,
    draft_height = opts.draft_height or config.defaults.draft_height,
  })
end

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
  state.set_target_terminal_bufnr(target_bufnr)
  vim.cmd("ClaudeDraftSend")
end

local function setup_send_keymaps(input_bufnr, claude1_bufnr, claude2_bufnr)
  vim.keymap.set({ "n", "i" }, "<C-CR>", function()
    send_to_target(claude1_bufnr)
  end, { buffer = input_bufnr, noremap = true, silent = true, desc = "Send draft to Claude 1" })

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
  if not state.is_dual_claude_active() then
    return
  end
  local cycle = state.get_dual_claude_cycle()
  local current = vim.api.nvim_get_current_win()
  local idx = find_index(cycle, current) or 0
  local next_win = cycle[(idx % #cycle) + 1]
  if next_win and vim.api.nvim_win_is_valid(next_win) then
    vim.api.nvim_set_current_win(next_win)
  end
end

function M.cycle_backward()
  if not state.is_dual_claude_active() then
    return
  end
  local cycle = state.get_dual_claude_cycle()
  local current = vim.api.nvim_get_current_win()
  local idx = find_index(cycle, current) or 0
  local prev_win = cycle[((idx - 2) % #cycle) + 1]
  if prev_win and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
end

function M.open_dual_claude(opts)
  opts = opts or {}
  local args = opts.args or ""
  local claude_cmd = M.dual_claude_config.command
  if args ~= "" then
    claude_cmd = claude_cmd .. " " .. args
  end

  vim.cmd("tabnew")

  vim.cmd("terminal " .. claude_cmd)
  local claude1_bufnr = vim.api.nvim_get_current_buf()
  local claude1_winid = vim.api.nvim_get_current_win()

  vim.cmd("rightbelow vsplit")
  vim.cmd("terminal " .. claude_cmd)
  local claude2_bufnr = vim.api.nvim_get_current_buf()
  local claude2_winid = vim.api.nvim_get_current_win()

  vim.cmd("botright split")
  vim.cmd("resize " .. tostring(M.dual_claude_config.input_height))
  local bottom_winid = vim.api.nvim_get_current_win()

  local left_pad_buf = create_padding_buf()
  vim.api.nvim_win_set_buf(bottom_winid, left_pad_buf)

  vim.cmd("rightbelow vsplit")
  local input_winid = vim.api.nvim_get_current_win()

  local input_bufnr
  if draft then
    input_bufnr = draft.open_input_buffer({
      claude_bufnr = claude1_bufnr,
      target_pattern = M.dual_claude_config.draft_target_pattern,
    })
  else
    input_bufnr = open_fallback_input_buffer("[DualClaude]")
  end

  vim.cmd("rightbelow vsplit")
  local right_pad_buf = create_padding_buf()
  local right_pad_winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_pad_winid, right_pad_buf)

  local pad_width = math.floor(vim.o.columns / 4)
  local left_pad_winid = bottom_winid
  setup_padding_win(left_pad_winid)
  vim.api.nvim_win_set_width(left_pad_winid, pad_width)

  setup_padding_win(right_pad_winid)
  vim.api.nvim_win_set_width(right_pad_winid, pad_width)

  state.set_dual_claude_state({
    claude1_winid = claude1_winid,
    claude2_winid = claude2_winid,
    input_winid = input_winid,
    claude1_bufnr = claude1_bufnr,
    claude2_bufnr = claude2_bufnr,
  })

  for _, bufnr in ipairs({ claude1_bufnr, claude2_bufnr, input_bufnr, left_pad_buf, right_pad_buf }) do
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      setup_cycle_keymaps(bufnr)
    end
  end

  setup_send_keymaps(input_bufnr, claude1_bufnr, claude2_bufnr)

  vim.api.nvim_set_current_win(input_winid)
  vim.cmd("startinsert")
end

return M
