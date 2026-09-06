-- 別ペインの Agent へプロンプトを送る。ペインの中身によって経路を分ける。
--
--   @nvim-server あり : 相手の nvim に RPC で式を評価させ、その中で chansend する。
--                       nvim のモードやカレントバッファに依存しない。
--   @nvim-server なし : ペインで Agent が直接動いているので tmux send-keys。
--
-- nvim 内 Agent へ send-keys を使ってはいけない。相手がノーマルモードだと文字列が
-- ノーマルモードのコマンドとして実行されバッファが壊れ、auto-command.lua の自動保存
-- （CursorHold / updatetime=300）で 0.3 秒後にディスクへ書かれる。
local config = require("agent_term.config")
local panes = require("agent_term.panes")

local M = {}

local RPC_TIMEOUT_MS = 2000

-- 相手 nvim 側で解決させる Agent ターミナルのパターン。1ペイン1エージェント前提。
local TARGET_PATTERNS = { "claude", "codex", "pi" }

local function write_temp(content)
  local path = vim.fn.tempname()
  local ok = pcall(vim.fn.writefile, { content }, path)
  if not ok then
    return nil
  end
  return path
end

-- 相手 nvim の terminals.external_send を呼ぶ。JSON はクォートの入れ子を避けるため
-- 一時ファイル経由で渡す。vim.system はシェルを介さないので引数のエスケープは不要。
local function rpc_send(sock, payload)
  local path = write_temp(payload)
  if not path then
    return false, "Failed to write temp payload"
  end

  local expr = (
    'luaeval(\'require("agent_term.terminals").external_send('
    .. 'table.concat(vim.fn.readfile(_A), "\\n")'
    .. ")', '%s')"
  ):format(path)

  local res = vim
    .system({ vim.v.progpath, "--server", sock, "--remote-expr", expr }, { timeout = RPC_TIMEOUT_MS })
    :wait()

  pcall(vim.fn.delete, path)

  if res.code ~= 0 then
    local detail = (res.stderr or ""):gsub("%s+$", "")
    if detail == "" then
      detail = "exit code " .. tostring(res.code) .. " (timeout の可能性)"
    end
    return false, "RPC failed: " .. detail
  end
  return true, "sent via nvim RPC"
end

local function tmux_send(pane_id, args)
  local cmd = { "tmux", "send-keys", "-t", pane_id }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { timeout = RPC_TIMEOUT_MS }):wait()
  if res.code ~= 0 then
    return false, "tmux send-keys failed: " .. ((res.stderr or ""):gsub("%s+$", ""))
  end
  return true
end

-- ペインで Agent が直接動いている場合。bracketed paste で包んでから Enter を送る。
local function send_keys_send(pane_id, content, clear_input)
  if clear_input then
    local clear_seq = config.draft.clear_input_sequence
    if type(clear_seq) == "string" and clear_seq ~= "" then
      local ok, err = tmux_send(pane_id, { "-l", "--", clear_seq })
      if not ok then
        return false, err
      end
    end
  end

  local ok, err = tmux_send(pane_id, { "-l", "--", "\27[200~" .. content .. "\27[201~" })
  if not ok then
    return false, err
  end

  ok, err = tmux_send(pane_id, { "Enter" })
  if not ok then
    return false, err
  end
  return true, "sent via tmux send-keys"
end

-- 送信前の検証。壊れる方向へ倒れないよう、失敗したら send-keys へフォールバックしない。
local function validate(pane)
  if not pane or not pane.pane_id or pane.pane_id == "" then
    return false, "宛先が選択されていない"
  end
  if not panes.exists(pane.pane_id) then
    return false, "宛先のペインが存在しない: " .. pane.pane_id
  end
  if pane.nvim_server and pane.nvim_server ~= "" then
    if not vim.uv.fs_stat(pane.nvim_server) then
      return false, "nvim のソケットが存在しない: " .. pane.nvim_server
    end
    return true
  end

  -- @nvim-server が空でも「素の Agent ペイン」とは限らない。この機能より前に
  -- 起動した nvim や、登録に失敗した nvim も空になる。そこへ send-keys すると
  -- 相手のバッファを壊すため、pane_current_command で明示的に確認する。
  if not panes.AGENT_COMMANDS[pane.command] then
    return false,
      ("送信経路を判定できない（cmd=%s, @nvim-server 未登録）。nvim なら再起動が必要"):format(
        pane.command ~= "" and pane.command or "?"
      )
  end
  return true
end

-- pane へ content を送る。opts.clear_input を false にすると入力欄のクリアを省く。
function M.send(pane, content, opts)
  opts = opts or {}
  local clear_input = opts.clear_input ~= false

  if content == nil or content == "" then
    return false, "本文が空"
  end

  local ok, err = validate(pane)
  if not ok then
    return false, err
  end

  if pane.nvim_server and pane.nvim_server ~= "" then
    if clear_input then
      local clear_seq = config.draft.clear_input_sequence
      if type(clear_seq) == "string" and clear_seq ~= "" then
        local payload = vim.fn.json_encode({
          target = TARGET_PATTERNS,
          command = clear_seq,
          opts = { add_newline = false, paste = false, exclude_current = false },
        })
        local cleared, cerr = rpc_send(pane.nvim_server, payload)
        if not cleared then
          return false, cerr
        end
      end
    end

    local payload = vim.fn.json_encode({
      target = TARGET_PATTERNS,
      command = content,
      opts = { add_newline = true, paste = true, exclude_current = false },
    })
    return rpc_send(pane.nvim_server, payload)
  end

  return send_keys_send(pane.pane_id, content, clear_input)
end

return M
