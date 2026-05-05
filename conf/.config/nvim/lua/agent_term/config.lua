local M = {}

M.defaults = {
  primary_command = "claude",
  secondary_command = "codex",
  draft_target_pattern = "claude",
  draft_height = 8,
  claude_ai_draft_height = 15,
  open_in_new_tab = true,
}

M.dual_claude = {
  command = "claude",
  input_height = 15,
  padding_width = 15,
  draft_height = 8,
  draft_target_pattern = "claude",
}

return M
