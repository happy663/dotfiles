local M = {}

M.draft = {
  fallback_target_patterns = { "claude", "codex" },
  attached_height = 8,
}

M.claude = {
  draft_height = 12,
}

M.codex = {
  draft_height = 12,
}

M.claude_codex = {
  draft_height = 8,
  open_in_new_tab = true,
}

M.claude_pair = {
  input_height = 15,
  padding_width = 15,
  fallback_target_patterns = { "claude" },
}

return M
