-- :Restart - セッションを保存してから :restart し、新プロセスで状態を復元する
-- nvim 0.12 の公式パターン「:mksession! Session.vim | restart source Session.vim」(:h :restart) をラップしたもの
-- 完全にリセットしたい時は素の :restart を使う
-- https://github.com/happy663/dotfiles/issues/290

local M = {}

local session_file = vim.fn.stdpath("state") .. "/restart-session.vim"
local octo_state_file = vim.fn.stdpath("state") .. "/restart-octo-windows.json"
local octo_placeholder_dir = vim.fn.stdpath("state") .. "/restart-octo-placeholders"

local function write_file(path, lines)
  local f = io.open(path, "w")
  if not f then
    return false
  end
  f:write(table.concat(lines, "\n"))
  f:write("\n")
  f:close()
  return true
end

local function normalize_octo_kind(kind)
  if kind == "pull_request" then
    return "pull"
  end
  return kind
end

local function octo_info_from_buffer(buf)
  local bufname = vim.api.nvim_buf_get_name(buf)
  local parsed = nil
  local ok_uri, uri = pcall(require, "octo.uri")
  if ok_uri and vim.startswith(bufname, "octo://") then
    parsed = uri.parse(bufname)
  end

  local octo_buffer = _G.octo_buffers and _G.octo_buffers[buf]
  if octo_buffer and octo_buffer.repo and octo_buffer.kind and octo_buffer.number then
    return {
      repo = octo_buffer.repo,
      kind = normalize_octo_kind(octo_buffer.kind),
      number = tostring(octo_buffer.number),
      hostname = parsed and parsed.hostname or nil,
    }
  end

  if not vim.startswith(bufname, "octo://") then
    return nil
  end

  if not parsed or not parsed.repo or not parsed.kind then
    return nil
  end

  local number = vim.b[buf].octo_issue_number or tonumber(parsed.id)
  if not number then
    return nil
  end

  return {
    repo = parsed.repo,
    kind = normalize_octo_kind(parsed.kind),
    number = tostring(number),
    hostname = parsed.hostname,
  }
end

local function prepare_octo_windows()
  local entries = {}

  vim.fn.mkdir(octo_placeholder_dir, "p")

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local info = octo_info_from_buffer(buf)

      if info and (info.kind == "issue" or info.kind == "pull") then
        local placeholder = string.format("%s/%d.md", octo_placeholder_dir, #entries + 1)
        write_file(placeholder, {
          "# Restart placeholder",
          "",
          string.format("Octo buffer: %s/%s/%s", info.repo, info.kind, info.number),
          "This buffer will be replaced after Neovim restarts.",
        })

        vim.api.nvim_win_call(win, function()
          vim.cmd("edit " .. vim.fn.fnameescape(placeholder))
        end)

        table.insert(entries, {
          placeholder = placeholder,
          repo = info.repo,
          kind = info.kind,
          number = info.number,
          hostname = info.hostname,
        })
      end
    end
  end

  if #entries == 0 then
    vim.fn.delete(octo_state_file)
    return
  end

  write_file(octo_state_file, { vim.json.encode(entries) })
end

local function restore_octo_window(entry)
  local placeholder_buf = vim.fn.bufnr(entry.placeholder)
  if placeholder_buf == -1 then
    return
  end

  local target_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == placeholder_buf then
      target_win = win
      break
    end
  end

  if not target_win then
    return
  end

  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    pcall(lazy.load, { plugins = { "octo.nvim" } })
  end

  local ok_octo, octo = pcall(require, "octo")
  if not ok_octo then
    vim.notify("[Restart] Octo の読み込みに失敗", vim.log.levels.WARN)
    return
  end

  octo.load(entry.repo, entry.kind, entry.number, entry.hostname, function(obj)
    if not vim.api.nvim_win_is_valid(target_win) then
      return
    end

    vim.api.nvim_win_call(target_win, function()
      octo.create_buffer(entry.kind, obj, entry.repo, true, entry.hostname)
      local octo_buf = vim.api.nvim_get_current_buf()
      vim.b[octo_buf].octo_title_processed = false
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(octo_buf) then
          pcall(vim.api.nvim_exec_autocmds, "BufEnter", { buffer = octo_buf, modeline = false })
        end
      end)
    end)

    if vim.api.nvim_buf_is_valid(placeholder_buf) then
      pcall(vim.api.nvim_buf_delete, placeholder_buf, { force = true })
    end
    vim.fn.delete(entry.placeholder)
  end)
end

local function restore_octo_windows()
  if vim.fn.filereadable(octo_state_file) ~= 1 then
    return
  end

  local ok, entries = pcall(vim.json.decode, table.concat(vim.fn.readfile(octo_state_file), "\n"))
  if not ok or type(entries) ~= "table" then
    vim.notify("[Restart] Octo 復元情報の読み込みに失敗", vim.log.levels.WARN)
    return
  end

  for _, entry in ipairs(entries) do
    restore_octo_window(entry)
  end

  vim.fn.delete(octo_state_file)
end

-- プラグインUI等の特殊バッファ(nvim-tree, octo, AIチャット等)のウィンドウは
-- セッションに入れると復元後に空バッファ化するため、保存前に閉じる
local function close_special_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype ~= "" then
        if #vim.api.nvim_list_wins() > 1 then
          pcall(vim.api.nvim_win_close, win, true)
        else
          -- 最後の1枚は閉じられないので空バッファに差し替える
          vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
        end
      end
    end
  end
end

local function restart_with_session()
  prepare_octo_windows()
  close_special_windows()

  -- terminal: agentターミナル等が履歴なしの素のコマンドで再スポーンされるのを防ぐ
  -- blank: 中身のない空ウィンドウを保存しない
  local saved_sessionoptions = vim.o.sessionoptions
  vim.opt.sessionoptions:remove({ "terminal", "blank" })
  local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(session_file))
  vim.o.sessionoptions = saved_sessionoptions
  if not ok then
    vim.notify("[Restart] セッション保存に失敗: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- セッションファイル末尾に自己削除を仕込みワンショット化する
  local f = io.open(session_file, "a")
  if f then
    f:write(("\ncall delete(%s)\n"):format(vim.fn.string(session_file)))
    f:close()
  end

  -- 未保存バッファがあれば内部の :qall が失敗して再起動は中断される(標準挙動に任せる)
  vim.cmd([[restart lua require("core.restart").resume()]])
end

local function load_session()
  if vim.fn.filereadable(session_file) ~= 1 then
    return
  end
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(session_file))
  if not ok then
    vim.notify("[Restart] セッション復元に失敗: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  restore_octo_windows()
end

-- :restart の [command] は起動シーケンスの途中で実行されることがあり、そのまま source すると
-- セッション読み込みが初期バッファを wipe した後に lazy.nvim が起動時イベントを再発火して
-- 「Invalid buffer id: 1」になる。VeryLazy 後まで遅延して競合を避ける
function M.resume()
  if vim.g.did_very_lazy then
    vim.schedule(load_session)
  else
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        vim.schedule(load_session)
      end,
    })
  end
end

vim.api.nvim_create_user_command("Restart", restart_with_session, {
  desc = "Restart Neovim and restore the current session (use :restart for a clean restart)",
})

vim.keymap.set("n", "<leader>re", "<cmd>Restart<CR>", { silent = true, desc = "Restart Neovim (restore session)" })

return M
