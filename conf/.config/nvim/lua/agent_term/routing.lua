local state = require("agent_term.state")
local draft = require("agent_term.draft")

local M = {}
local setup_done = false
-- 自動移送中の再入防止フラグ
local relocating = false

-- 作業タブへ移送する対象（実ファイルを編集する通常バッファ）かどうか。
-- ターミナル・nofile・名前なしバッファは対象外。
function M.is_relocatable_file_buf(bufnr)
  if not state.is_valid_buf(bufnr) then
    return false
  end
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  if vim.api.nvim_buf_get_name(bufnr) == "" then
    return false
  end
  return true
end

-- 作業タブへ移動する。無ければ新規タブを作成して現在タブにする。
local function goto_or_create_work_tabpage()
  local work = state.get_work_tabpage()
  if work then
    vim.api.nvim_set_current_tabpage(work)
    return work
  end
  vim.cmd("tabnew")
  return vim.api.nvim_get_current_tabpage()
end

-- bufnr を作業タブの現在ウィンドウで開く。cursor を渡すと位置を引き継ぐ。
function M.open_buf_in_work_tab(bufnr, cursor)
  if not state.is_valid_buf(bufnr) then
    return false
  end

  goto_or_create_work_tabpage()
  pcall(vim.api.nvim_set_current_buf, bufnr)
  if cursor then
    pcall(vim.api.nvim_win_set_cursor, 0, cursor)
  end
  return true
end

-- 最近使った Agent タブへ移動し、ドラフト入力をフォーカスする（要望2）。
-- Agent タブが無ければ false を返す。
function M.goto_agent_draft()
  local agent_tab = state.get_agent_tabpage()
  if not agent_tab then
    return false
  end

  vim.api.nvim_set_current_tabpage(agent_tab)
  return draft.focus_or_open({})
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  local group = vim.api.nvim_create_augroup("AgentTermRouting", { clear = true })

  -- タブ離脱時に分類を確定して MRU に記録する。
  -- 離脱時はタブの構成（ターミナル/ドラフトの有無）が確定しているため正確に分類できる。
  vim.api.nvim_create_autocmd("TabLeave", {
    group = group,
    callback = function()
      state.record_tabpage(vim.api.nvim_get_current_tabpage())
    end,
  })

  -- 起動直後の現在タブも記録しておく。
  state.record_tabpage(vim.api.nvim_get_current_tabpage())

  -- Agent タブで通常ファイルが開かれたら作業タブへ自動移送する（要望1）。
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(args)
      if relocating then
        return
      end

      local bufnr = args.buf
      if not M.is_relocatable_file_buf(bufnr) then
        return
      end
      if not state.is_agent_tabpage(0) then
        return
      end

      local win = vim.api.nvim_get_current_win()
      -- フロートウィンドウ（補完・プレビュー等）は対象外
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end

      local cursor = vim.api.nvim_win_get_cursor(win)
      -- このウィンドウに直前まで表示していたバッファ（復帰用）
      local alt = vim.fn.bufnr("#")

      relocating = true
      vim.schedule(function()
        -- Agent タブ側のウィンドウを元のバッファへ戻す
        if
          vim.api.nvim_win_is_valid(win)
          and vim.api.nvim_win_get_buf(win) == bufnr
          and state.is_valid_buf(alt)
          and alt ~= bufnr
        then
          pcall(vim.api.nvim_win_set_buf, win, alt)
        end

        M.open_buf_in_work_tab(bufnr, cursor)
        relocating = false
      end)
    end,
  })
end

return M
