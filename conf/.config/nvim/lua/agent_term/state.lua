local M = {}

function M.is_valid_buf(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

function M.get_draft_bufnr()
  if M.is_valid_buf(vim.t.claude_input_bufnr) then
    return vim.t.claude_input_bufnr
  end
  return nil
end

function M.set_draft_bufnr(bufnr)
  vim.t.claude_input_bufnr = bufnr
end

function M.get_target_terminal_bufnr()
  if M.is_valid_buf(vim.t.claude_terminal_bufnr) and vim.bo[vim.t.claude_terminal_bufnr].buftype == "terminal" then
    return vim.t.claude_terminal_bufnr
  end
  return nil
end

function M.set_target_terminal_bufnr(bufnr)
  if M.is_valid_buf(bufnr) then
    vim.t.claude_terminal_bufnr = bufnr
  end
end

function M.get_target_pattern(default_pattern)
  return vim.t.claude_input_target_pattern or default_pattern
end

function M.set_target_pattern(pattern)
  if type(pattern) == "string" and pattern ~= "" then
    vim.t.claude_input_target_pattern = pattern
  end
end

function M.set_prev_winid(winid)
  vim.t.claude_input_prev_winid = winid
end

function M.get_prev_winid()
  return vim.t.claude_input_prev_winid
end

local function normalize_height(height)
  if type(height) == "number" and height > 0 then
    return height
  end
  return nil
end

function M.get_draft_height(default_height)
  return normalize_height(vim.t.claude_input_height) or normalize_height(default_height)
end

function M.set_draft_height(height)
  local normalized = normalize_height(height)
  if normalized then
    vim.t.claude_input_height = normalized
  end
end

function M.set_dual_claude_state(state)
  vim.t.dual_claude_active = true
  vim.t.dual_claude_claude1_winid = state.claude1_winid
  vim.t.dual_claude_claude2_winid = state.claude2_winid
  vim.t.dual_claude_input_winid = state.input_winid
  vim.t.dual_claude_claude1_bufnr = state.claude1_bufnr
  vim.t.dual_claude_claude2_bufnr = state.claude2_bufnr
  M.set_target_terminal_bufnr(state.claude1_bufnr)
end

function M.is_dual_claude_active()
  return vim.t.dual_claude_active == true
end

function M.get_dual_claude_cycle()
  return {
    vim.t.dual_claude_input_winid,
    vim.t.dual_claude_claude1_winid,
    vim.t.dual_claude_claude2_winid,
  }
end

return M
