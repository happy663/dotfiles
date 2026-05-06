local config = require("agent_term.config")
local draft = require("agent_term.draft")
local state = require("agent_term.state")

local CLAUDE_COMMAND = "claude"
local CODEX_COMMAND = "codex"

local M = {}
M.claude_pair_config = config.claude_pair

local function open_fallback_input_buffer(label)
  vim.notify(label .. " agent draft module not found", vim.log.levels.WARN)
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "markdown"
  vim.cmd("startinsert")
  return vim.api.nvim_get_current_buf()
end

function M.open_term_draft(opts)
  opts = opts or {}
  local target_bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[target_bufnr].buftype ~= "terminal" then
    vim.notify("[AgentDraft] Run this command from a terminal buffer", vim.log.levels.WARN)
    return nil
  end

  vim.cmd("belowright split")
  return draft.open_input_buffer({
    target_bufnr = target_bufnr,
    draft_height = opts.draft_height or config.draft.attached_height,
  })
end

function M.open_agent_codex(opts)
  opts = opts or {}
  local codex_cmd = opts.command or CODEX_COMMAND
  if opts.args and opts.args ~= "" then
    codex_cmd = codex_cmd .. " " .. opts.args
  end

  if opts.open_in_new_tab ~= false then
    vim.cmd("tabnew")
  end
  vim.cmd("terminal " .. codex_cmd)
  local target_bufnr = vim.api.nvim_get_current_buf()
  -- codex termの固有設定
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = target_bufnr, noremap = true, silent = true })

  state.set_target_terminal_bufnr(target_bufnr)

  vim.cmd("belowright split")
  return draft.open_input_buffer({
    target_bufnr = target_bufnr,
    fallback_target_patterns = CODEX_COMMAND,
    draft_height = config.codex.draft_height,
  })
end

function M.open_agent_claude(opts)
  opts = opts or {}
  local claude_cmd = opts.command or CLAUDE_COMMAND
  if opts.args and opts.args ~= "" then
    claude_cmd = claude_cmd .. " " .. opts.args
  end

  vim.cmd("tabnew")
  vim.cmd("terminal " .. claude_cmd)
  local target_bufnr = vim.api.nvim_get_current_buf()
  state.set_target_terminal_bufnr(target_bufnr)

  vim.cmd("belowright split")
  return draft.open_input_buffer({
    target_bufnr = target_bufnr,
    fallback_target_patterns = opts.fallback_target_patterns or config.draft.fallback_target_patterns,
    -- draft_height = config.claude.draft_height,
    draft_height = config.claude.draft_height,
  })
end

function M.open_agent_claude_codex(opts)
  opts = opts or {}
  if opts.open_in_new_tab ~= false and config.claude_codex.open_in_new_tab then
    vim.cmd("tabnew")
  end

  local claude_cmd = opts.claude_command or CLAUDE_COMMAND
  if opts.args and opts.args ~= "" then
    claude_cmd = claude_cmd .. " " .. opts.args
  end

  vim.cmd("terminal " .. claude_cmd)
  local claude_target_bufnr = vim.api.nvim_get_current_buf()
  state.set_target_terminal_bufnr(claude_target_bufnr)

  vim.cmd("vsplit")
  local codex_cmd = opts.codex_command or CODEX_COMMAND
  vim.cmd("terminal " .. codex_cmd)
  local codex_bufnr = vim.api.nvim_get_current_buf()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = codex_bufnr, noremap = true, silent = true })

  vim.cmd("wincmd h")
  vim.cmd("belowright split")

  return draft.open_input_buffer({
    target_bufnr = claude_target_bufnr,
    fallback_target_patterns = opts.fallback_target_patterns or config.draft.fallback_target_patterns,
    draft_height = opts.draft_height or config.claude_codex.draft_height,
  })
end

vim.api.nvim_set_hl(0, "AgentClaudePairPadding", { bg = "#1a1a2e" })

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
  vim.wo[winid].winhighlight = "Normal:AgentClaudePairPadding,EndOfBuffer:AgentClaudePairPadding"
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
  vim.cmd("AgentDraftSend")
end

local function setup_send_keymaps(input_bufnr, left_bufnr, right_bufnr)
  vim.keymap.set({ "n", "i" }, "<C-CR>", function()
    send_to_target(left_bufnr)
  end, { buffer = input_bufnr, noremap = true, silent = true, desc = "Send draft to Claude 1" })

  vim.keymap.set({ "n", "i" }, "<S-CR>", function()
    send_to_target(right_bufnr)
  end, { buffer = input_bufnr, noremap = true, silent = true, desc = "Send draft to Claude 2" })
end

local function setup_cycle_keymaps(bufnr)
  vim.keymap.set({ "n", "t" }, "<C-k>", function()
    M.cycle_forward()
  end, { buffer = bufnr, noremap = true, silent = true, desc = "AgentClaudePair: cycle forward" })

  vim.keymap.set({ "n", "t" }, "<C-j>", function()
    M.cycle_backward()
  end, { buffer = bufnr, noremap = true, silent = true, desc = "AgentClaudePair: cycle backward" })
end

function M.cycle_forward()
  if not state.is_agent_claude_pair_active() then
    return
  end
  local cycle = state.get_agent_claude_pair_cycle()
  local current = vim.api.nvim_get_current_win()
  local idx = find_index(cycle, current) or 0
  local next_win = cycle[(idx % #cycle) + 1]
  if next_win and vim.api.nvim_win_is_valid(next_win) then
    vim.api.nvim_set_current_win(next_win)
  end
end

function M.cycle_backward()
  if not state.is_agent_claude_pair_active() then
    return
  end
  local cycle = state.get_agent_claude_pair_cycle()
  local current = vim.api.nvim_get_current_win()
  local idx = find_index(cycle, current) or 0
  local prev_win = cycle[((idx - 2) % #cycle) + 1]
  if prev_win and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
end

function M.open_agent_claude_pair(opts)
  opts = opts or {}
  local args = opts.args or ""
  local claude_cmd = opts.command or CLAUDE_COMMAND
  if args ~= "" then
    claude_cmd = claude_cmd .. " " .. args
  end

  vim.cmd("tabnew")

  vim.cmd("terminal " .. claude_cmd)
  local left_bufnr = vim.api.nvim_get_current_buf()
  local left_winid = vim.api.nvim_get_current_win()

  vim.cmd("rightbelow vsplit")
  vim.cmd("terminal " .. claude_cmd)
  local right_bufnr = vim.api.nvim_get_current_buf()
  local right_winid = vim.api.nvim_get_current_win()

  vim.cmd("botright split")
  vim.cmd("resize " .. tostring(M.claude_pair_config.input_height))
  local bottom_winid = vim.api.nvim_get_current_win()

  local left_pad_buf = create_padding_buf()
  vim.api.nvim_win_set_buf(bottom_winid, left_pad_buf)

  vim.cmd("rightbelow vsplit")
  local input_winid = vim.api.nvim_get_current_win()

  local input_bufnr
  if draft then
    input_bufnr = draft.open_input_buffer({
      target_bufnr = left_bufnr,
      fallback_target_patterns = M.claude_pair_config.fallback_target_patterns,
    })
  else
    input_bufnr = open_fallback_input_buffer("[AgentClaudePair]")
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

  state.set_agent_claude_pair_state({
    left_winid = left_winid,
    right_winid = right_winid,
    input_winid = input_winid,
    left_bufnr = left_bufnr,
    right_bufnr = right_bufnr,
  })

  for _, bufnr in ipairs({ left_bufnr, right_bufnr, input_bufnr, left_pad_buf, right_pad_buf }) do
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      setup_cycle_keymaps(bufnr)
    end
  end

  setup_send_keymaps(input_bufnr, left_bufnr, right_bufnr)

  vim.api.nvim_set_current_win(input_winid)
  vim.cmd("startinsert")
end

return M
