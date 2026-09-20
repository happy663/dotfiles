-- ピッカーのプレビュー用に、宛先ペインの内容を取得する。
--
-- 経路は送信（remote_send）と同じ2つに分かれる。ここが要点で、
-- 「プレビューに見えている内容」と「プロンプトが送られる先」を一致させる。
--
--   @nvim-server あり : 相手 nvim の terminals.external_preview を RPC で評価する。
--                       send と同じ find_terminal_by_pattern で解決するため、
--                       1ペインに複数 agent がいても送信先と同じ terminal になる。
--   @nvim-server なし : tmux capture-pane。ペインそのものが送信先なので一致する。
--
-- 取得は同期。実測で capture-pane は 5ms、RPC は 10ms 程度なので、
-- 5秒間隔の tick と選択変更（50ms debounce）に載せても UI を止める時間はほぼ無い。
local config = require("agent_term.config")
local remote_send = require("agent_term.picker.remote_send")

local M = {}

-- send 側と同じパターン。1ペイン1エージェントが前提。
local TARGET_PATTERNS = { "claude", "codex", "pi" }

-- TUI は行末を画面幅まで空白で埋めるので、落としておかないと空行だらけに見える。
local function trim_eol(line)
  return (line:gsub("%s+$", ""))
end

-- エラーの詳細は複数行になり得る（Lua の traceback、複数行の stderr など）。
-- 表示側で1行として扱えるよう、空白を畳んで1行にする。
local function one_line(message)
  return (tostring(message):gsub("%s+", " "))
end

-- 相手の nvim が external_preview を持つ前の設定で起動していると「関数が無い」エラーになる。
-- 原因が分かるようにヒントを足す（make link 後に起動済みの nvim は再起動が必要）。
-- traceback には関数名として external_preview が現れるので、「nil value」も見て区別する。
local function describe_rpc_error(message)
  local text = one_line(message)
  if text:find("external_preview", 1, true) and text:find("nil value", 1, true) then
    text = text .. " (相手の nvim が古い設定で起動している。nvim を再起動すると直る)"
  end
  return text
end

-- 相手 nvim から terminal buffer の末尾を取り出す。
local function rpc_lines(sock, history_lines)
  local payload = vim.fn.json_encode({
    target = TARGET_PATTERNS,
    lines = history_lines,
  })

  local path = vim.fn.tempname()
  if not pcall(vim.fn.writefile, { payload }, path) then
    return nil, "一時ファイルを書けない"
  end

  -- 本文を引数に埋め込むとクォートが入れ子になるので、send と同じく一時ファイル経由で渡す。
  -- vim.system はシェルを介さないため引数のエスケープは不要。
  local expr = (
    'luaeval(\'require("agent_term.local.terminals").external_preview('
    .. 'table.concat(vim.fn.readfile(_A), "\\n")'
    .. ")', '%s')"
  ):format(path)

  local out, err = remote_send.remote_expr(sock, expr, config.send_to.preview.fetch_timeout_ms)
  pcall(vim.fn.delete, path)

  if not out then
    return nil, describe_rpc_error(err)
  end

  local text = vim.trim(out)
  if text == "" then
    return nil, "RPC の応答が空"
  end

  local ok, decoded = pcall(vim.fn.json_decode, text)
  if not ok or type(decoded) ~= "table" then
    return nil, "RPC の応答を解釈できない"
  end
  if decoded.error then
    return nil, one_line(decoded.error)
  end

  return decoded.lines or {}, nil
end

-- 素の agent ペインから画面を取り出す。
-- -J（折返しの結合）は使わない。TUI は画面幅ちょうどに行を描くので、結合すると
-- 1行が画面幅を超えて nowrap のプレビューで見切れる。nvim 側が terminal buffer の
-- 画面行を返すのと揃える意味でも、行はそのまま取る。
local function capture_lines(pane, history_lines)
  local res = vim
    .system(
      { "tmux", "capture-pane", "-p", "-S", "-" .. history_lines, "-t", pane.pane_id },
      { timeout = config.send_to.preview.fetch_timeout_ms }
    )
    :wait()

  if res.code ~= 0 then
    local detail = (res.stderr or ""):gsub("%s+$", "")
    if detail == "" then
      detail = "exit code " .. tostring(res.code)
    end
    return nil, "capture-pane failed: " .. one_line(detail)
  end

  local lines = vim.split(res.stdout or "", "\n", { plain = true })
  -- 末尾の改行で生まれる空要素は落とす。
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  return lines, nil
end

-- pane の内容を末尾 history_lines 行ぶん返す。戻り値は (lines, nil) か (nil, 理由)。
function M.fetch(pane, opts)
  opts = opts or {}
  if not pane or not pane.pane_id or pane.pane_id == "" then
    return nil, "宛先が指定されていない"
  end

  local history_lines = opts.history_lines or config.send_to.preview.history_lines

  local lines, err
  if pane.nvim_server and pane.nvim_server ~= "" then
    lines, err = rpc_lines(pane.nvim_server, history_lines)
  else
    lines, err = capture_lines(pane, history_lines)
  end

  if not lines then
    return nil, err
  end

  local trimmed = {}
  for i, line in ipairs(lines) do
    trimmed[i] = trim_eol(line)
  end
  return trimmed, nil
end

return M
