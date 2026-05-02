-- terminal_bridge.lua
-- ターミナルバッファへのコマンド送信を管理するモジュール
-- Claude CodeとCodex間の双方向通信を実現

local M = {}

-- ログ設定
M.log_level = "ERROR" -- DEBUG, INFO, WARN, ERROR

---
-- ログ出力
-- @param level string ログレベル
-- @param msg string メッセージ
---
M.log = function(level, msg)
  local levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
  local current_level = levels[M.log_level] or 1
  local msg_level = levels[level] or 1

  if msg_level >= current_level then
    local log_msg = string.format("[terminal_bridge:%s] %s", level, msg)
    -- DEBUGとINFOはprint、WARN/ERRORはvim.notify
    if level == "ERROR" then
      vim.notify(log_msg, vim.log.levels.ERROR)
    elseif level == "WARN" then
      vim.notify(log_msg, vim.log.levels.WARN)
    else
      print(log_msg)
    end
  end
end

---
-- すべてのターミナルバッファを取得
-- @return table ターミナル情報のリスト {bufnr, job_id, name}
---
function M.get_all_terminals()
  local terminals = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal" then
      local job_id = vim.b[bufnr].terminal_job_id
      local name = vim.api.nvim_buf_get_name(bufnr)
      if job_id then
        table.insert(terminals, {
          bufnr = bufnr,
          job_id = job_id,
          name = name,
        })
        M.log("DEBUG", string.format("  Found terminal: bufnr=%d, job_id=%d, name=%s", bufnr, job_id, name))
      end
    end
  end

  M.log("INFO", string.format("get_all_terminals() found %d terminals", #terminals))
  return terminals
end

---
-- インデックスでターミナルを取得
-- @param index number ターミナルのインデックス（1始まり）
-- @param exclude_current boolean 現在のバッファを除外するか（デフォルト: false）
-- @return table|nil ターミナル情報
---
function M.find_terminal_by_index(index, exclude_current)
  M.log(
    "DEBUG",
    string.format("find_terminal_by_index(index=%s, exclude_current=%s)", tostring(index), tostring(exclude_current))
  )

  local current_bufnr = vim.api.nvim_get_current_buf()
  local terminals = M.get_all_terminals()

  local filtered = {}
  for _, term in ipairs(terminals) do
    if not (exclude_current and term.bufnr == current_bufnr) then
      table.insert(filtered, term)
    end
  end

  M.log("DEBUG", string.format("  Filtered terminals count: %d", #filtered))

  local result = filtered[index]
  if result then
    M.log("INFO", string.format("find_terminal_by_index() found: bufnr=%d, name=%s", result.bufnr, result.name))
  else
    M.log("WARN", string.format("find_terminal_by_index() not found for index=%d", index))
  end

  return result
end

---
-- パターンに一致するターミナルを検索
-- @param pattern string Luaパターン（例: "codex", "claude"）
-- @param exclude_current boolean 現在のバッファを除外するか
-- @return table|nil 一致したターミナル情報、または nil
---
function M.find_terminal_by_pattern(pattern, exclude_current)
  M.log(
    "DEBUG",
    string.format("find_terminal_by_pattern(pattern=%s, exclude_current=%s)", pattern, tostring(exclude_current))
  )

  local current_bufnr = vim.api.nvim_get_current_buf()
  local terminals = M.get_all_terminals()

  for _, term in ipairs(terminals) do
    if exclude_current and term.bufnr == current_bufnr then
      goto continue
    end

    if string.match(term.name:lower(), pattern:lower()) then
      M.log("INFO", string.format("find_terminal_by_pattern() found: bufnr=%d, name=%s", term.bufnr, term.name))
      return term
    end

    ::continue::
  end

  M.log("WARN", string.format("find_terminal_by_pattern() not found for pattern=%s", pattern))
  return nil
end

---
-- ターミナルにコマンドを送信
-- @param target string|number パターン文字列またはインデックス
-- @param command string 送信するコマンド
-- @param opts table オプション {add_newline: boolean, exclude_current: boolean, paste: boolean}
-- @return boolean, string 成功/失敗とメッセージ
---
function M.send_command(target, command, opts)
  M.log("DEBUG", string.format("send_command(target=%s, command=%s)", tostring(target), command))

  opts = opts or {}
  local add_newline = opts.add_newline ~= false -- デフォルトでtrue
  local exclude_current = opts.exclude_current or false -- デフォルトでfalse
  local paste = opts.paste == true -- デフォルトでfalse（オプトイン）

  local terminal

  if type(target) == "number" then
    terminal = M.find_terminal_by_index(target, exclude_current)
  else
    terminal = M.find_terminal_by_pattern(target, exclude_current)
  end

  if not terminal then
    local err_msg = "Terminal not found: " .. tostring(target)
    M.log("ERROR", err_msg)
    return false, err_msg
  end

  -- paste オプション有効時はブラケットペーストシーケンスで囲む。
  -- TUI 側 (claudecode 等) で本文中の \n が「Enter（送信）」として解釈される問題を回避するため。
  local cmd_to_send = paste and ("\27[200~" .. command .. "\27[201~") or command

  M.log("DEBUG", string.format("  Sending to job_id=%d (paste=%s): %s", terminal.job_id, tostring(paste), cmd_to_send))

  -- まずコマンドテキストを送信
  local ok, err = pcall(vim.fn.chansend, terminal.job_id, cmd_to_send)
  if not ok then
    local err_msg = "Failed to send command: " .. tostring(err)
    M.log("ERROR", err_msg)
    return false, err_msg
  end

  -- 改行が必要な場合、ジョブに直接 "\r" を送って同期的に実行させる
  -- feedkeys + window切替は typeahead キューに入るため、呼び出し元が直後に window を切り替えると取りこぼされる
  if add_newline then
    local ok_nl, err_nl = pcall(vim.fn.chansend, terminal.job_id, "\r")
    if not ok_nl then
      M.log("WARN", "Failed to send newline: " .. tostring(err_nl))
    end
  end

  local success_msg = string.format("Command sent to terminal %d (%s)", target, terminal.name)
  M.log("INFO", success_msg)
  return true, success_msg
end

---
-- 外部から呼び出し可能なインターフェース（nvr用）
-- @param args string JSON形式の引数 {target, command, opts}
-- @return string 結果（JSON形式）
---
function M.external_send(args)
  M.log("DEBUG", string.format("external_send() received: %s", args))

  local ok, params = pcall(vim.fn.json_decode, args)
  if not ok then
    local err_msg = "Invalid JSON: " .. args
    M.log("ERROR", err_msg)
    return vim.fn.json_encode({ success = false, message = err_msg })
  end

  M.log(
    "DEBUG",
    string.format("  Parsed params: target=%s, command=%s", tostring(params.target), tostring(params.command))
  )

  local success, message = M.send_command(params.target or 1, params.command or "", params.opts or {})

  local result = vim.fn.json_encode({
    success = success,
    message = message,
  })

  M.log("DEBUG", string.format("external_send() result: %s", result))
  return result
end

---
-- ターミナル一覧を取得（外部から呼び出し可能）
-- @return string ターミナル一覧（JSON形式）
---
function M.list_terminals()
  M.log("DEBUG", "list_terminals() called")

  local terminals = M.get_all_terminals()
  local result = {}

  for i, term in ipairs(terminals) do
    table.insert(result, {
      index = i,
      bufnr = term.bufnr,
      name = term.name,
    })
  end

  local json_result = vim.fn.json_encode(result)
  M.log("DEBUG", string.format("list_terminals() result: %s", json_result))
  return json_result
end

return M

