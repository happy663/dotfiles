local config = require("agent_term.config")
local draft = require("agent_term.local.draft")
local state = require("agent_term.local.state")
local message_nav = require("agent_term.message_nav")

local CLAUDE_COMMAND = "claude"
local CODEX_COMMAND = "codex"
local PI_COMMAND = "pi"

local M = {}

-- NvimTree等がターミナルウィンドウに漏れ出させたウィンドウローカルwinhighlight
-- (Normal:NvimTreeNormal 等) をクリアし、ターミナル文字色がグレーになるのを防ぐ。
-- 原因: tabnewで作ったターミナルウィンドウにNvimTreeのwinhlが波及する。
-- クリアすればグローバルNormal(明色)が復活して文字が白くなる。
-- 遅延autocmdで再汚染される可能性があるため、同期+vim.scheduleの2段で確実に消す。
-- @param winid? number 対象ウィンドウ(省略時は現在ウィンドウ)
-- https://github.com/happy663/dotfiles/issues/308
local function clear_term_winhighlight(winid)
  winid = winid or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  vim.wo[winid].winhighlight = ""
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(winid) then
      vim.wo[winid].winhighlight = ""
    end
  end)
end

function M.open_term_draft(opts)
  opts = opts or {}
  local target_bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[target_bufnr].buftype ~= "terminal" then
    vim.notify("[AgentDraft] Run this command from a terminal buffer", vim.log.levels.WARN)
    return nil
  end

  return draft.open_for_target({
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
    state.mark_current_tab_as_agent()
  end
  vim.cmd("startinsert")
  vim.cmd("terminal " .. codex_cmd)
  local target_bufnr = vim.api.nvim_get_current_buf()
  clear_term_winhighlight()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = target_bufnr, noremap = true, silent = true })

  state.set_target_terminal_bufnr(target_bufnr)

  if opts.open_draft == false then
    return target_bufnr
  end

  return draft.open_for_target({
    target_bufnr = target_bufnr,
    fallback_target_patterns = CODEX_COMMAND,
    draft_height = config.codex.draft_height,
  })
end

function M.open_agent_pi(opts)
  opts = opts or {}
  local pi_cmd = opts.command or PI_COMMAND
  if opts.args and opts.args ~= "" then
    pi_cmd = pi_cmd .. " " .. opts.args
  end

  if opts.open_in_new_tab ~= false then
    vim.cmd("tabnew")
    state.mark_current_tab_as_agent()
  end
  vim.cmd("startinsert")
  vim.cmd("terminal " .. pi_cmd)
  local target_bufnr = vim.api.nvim_get_current_buf()
  clear_term_winhighlight()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = target_bufnr, noremap = true, silent = true })
  message_nav.attach(target_bufnr, "pi")

  state.set_target_terminal_bufnr(target_bufnr)

  if opts.open_draft == false then
    return target_bufnr
  end

  return draft.open_for_target({
    target_bufnr = target_bufnr,
    fallback_target_patterns = PI_COMMAND,
    draft_height = config.pi.draft_height,
  })
end

function M.open_agent_claude(opts)
  opts = opts or {}
  local claude_cmd = opts.command or CLAUDE_COMMAND
  if opts.args and opts.args ~= "" then
    claude_cmd = claude_cmd .. " " .. opts.args
  end

  vim.cmd("tabnew")
  state.mark_current_tab_as_agent()
  vim.cmd("startinsert")
  vim.cmd("terminal " .. claude_cmd)
  local target_bufnr = vim.api.nvim_get_current_buf()
  clear_term_winhighlight()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = target_bufnr, noremap = true, silent = true })
  message_nav.attach(target_bufnr, "claude")
  state.set_target_terminal_bufnr(target_bufnr)

  if opts.open_draft == false then
    return target_bufnr
  end

  return draft.open_for_target({
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
    state.mark_current_tab_as_agent()
  end

  local claude_cmd = opts.claude_command or CLAUDE_COMMAND
  if opts.args and opts.args ~= "" then
    claude_cmd = claude_cmd .. " " .. opts.args
  end

  vim.cmd("terminal " .. claude_cmd)
  local claude_target_bufnr = vim.api.nvim_get_current_buf()
  clear_term_winhighlight()
  message_nav.attach(claude_target_bufnr, "claude")
  state.set_target_terminal_bufnr(claude_target_bufnr)

  vim.cmd("vsplit")
  local codex_cmd = opts.codex_command or CODEX_COMMAND
  vim.cmd("terminal " .. codex_cmd)
  local codex_bufnr = vim.api.nvim_get_current_buf()
  clear_term_winhighlight()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = codex_bufnr, noremap = true, silent = true })

  vim.cmd("wincmd h")

  return draft.open_for_target({
    target_bufnr = claude_target_bufnr,
    fallback_target_patterns = opts.fallback_target_patterns or config.draft.fallback_target_patterns,
    draft_height = opts.draft_height or config.claude_codex.draft_height,
  })
end

return M
