local M = {}

M.draft = {
  fallback_target_patterns = { "claude", "codex" },
  attached_height = 8,
  -- 送信前にターゲットターミナルへ送る入力クリアシーケンス。
  -- デフォルトは backspace (\x7f) を多めに送ることで、改行込みの複数行入力も
  -- TUI 実装に依存せず削除する。Ctrl+U (\x15) は readline multiline や一部 TUI で
  -- 現在行しかクリアできないためデフォルトでは使わない。
  clear_input_sequence = string.rep("\x7f", 5000),
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
