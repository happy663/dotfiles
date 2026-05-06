local M = {}

function M.is_valid_buf(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

function M.get_draft_bufnr()
  if M.is_valid_buf(vim.t.agent_input_bufnr) then
    return vim.t.agent_input_bufnr
  end
  return nil
end

function M.set_draft_bufnr(bufnr)
  vim.t.agent_input_bufnr = bufnr
end

function M.get_target_terminal_bufnr()
  if M.is_valid_buf(vim.t.agent_terminal_bufnr) and vim.bo[vim.t.agent_terminal_bufnr].buftype == "terminal" then
    return vim.t.agent_terminal_bufnr
  end
  return nil
end

function M.set_target_terminal_bufnr(bufnr)
  if M.is_valid_buf(bufnr) then
    vim.t.agent_terminal_bufnr = bufnr
  end
end

function M.get_fallback_target_patterns(default_patterns)
  return vim.t.agent_input_fallback_target_patterns or default_patterns
end

function M.set_fallback_target_patterns(patterns)
  if type(patterns) == "string" and patterns ~= "" then
    vim.t.agent_input_fallback_target_patterns = patterns
  elseif type(patterns) == "table" and #patterns > 0 then
    vim.t.agent_input_fallback_target_patterns = patterns
  end
end

function M.set_prev_winid(winid)
  vim.t.agent_input_prev_winid = winid
end

function M.get_prev_winid()
  return vim.t.agent_input_prev_winid
end

local function normalize_height(height)
  if type(height) == "number" and height > 0 then
    return height
  end
  return nil
end

function M.get_draft_height(default_height)
  return normalize_height(vim.t.agent_input_height) or normalize_height(default_height)
end

function M.set_draft_height(height)
  local normalized = normalize_height(height)
  if normalized then
    vim.t.agent_input_height = normalized
  end
end

function M.set_agent_claude_pair_state(pair_state)
  vim.t.agent_claude_pair_active = true
  vim.t.agent_claude_pair_left_winid = pair_state.left_winid
  vim.t.agent_claude_pair_right_winid = pair_state.right_winid
  vim.t.agent_claude_pair_input_winid = pair_state.input_winid
  vim.t.agent_claude_pair_left_bufnr = pair_state.left_bufnr
  vim.t.agent_claude_pair_right_bufnr = pair_state.right_bufnr
  M.set_target_terminal_bufnr(pair_state.left_bufnr)
end

function M.is_agent_claude_pair_active()
  return vim.t.agent_claude_pair_active == true
end

function M.get_agent_claude_pair_cycle()
  return {
    vim.t.agent_claude_pair_input_winid,
    vim.t.agent_claude_pair_left_winid,
    vim.t.agent_claude_pair_right_winid,
  }
end

return M
