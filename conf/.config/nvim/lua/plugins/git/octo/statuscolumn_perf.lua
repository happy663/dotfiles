-- octo.nvim の statuscolumn（コメント範囲の ┌╴│└╴ 表示）を高速化する。
--
-- 上流の get_sign() は画面の1行を描くたびに、その行が属するコメント全体の
-- 表示高さを nvim_win_text_height() で数え直す。本文の長いPR/issueでは
-- 「表示行数 × コメント行数」の計算になり、カーソル移動や入力が重くなる
-- （挿入モードでは1文字ごとにtreesitterのconcealキャッシュも消えるため特に重い）。
--
-- 全体の高さは `height == 1`（1画面行に収まるか）の判定にしか使っていないので、
-- max_height = 2 で数えるのを打ち切る。最終行の高さは最終行を描くときだけ数える。
-- 表示される記号は上流の実装と同じ。
--
-- 上流の内部構造（get_sign の upvalue `comments` / `corners`）に依存するため、
-- 見つからなければ何もせず上流の実装のまま動かす。

local M = {}

---@param fn function
---@return table? comments
---@return table? corners
local function find_upvalues(fn)
  local comments, corners
  for i = 1, 50 do
    local name, value = debug.getupvalue(fn, i)
    if not name then
      break
    end
    if name == "comments" then
      comments = value
    elseif name == "corners" then
      corners = value
    end
  end
  return comments, corners
end

---@param comments table<integer, { from: integer, to: integer, dirty: boolean }[]>
---@param corners { top: string, middle: string, last: string, single: string }
local function make_get_sign(comments, corners)
  local function get_sign(buf, lnum, vnum, win)
    lnum = lnum - 1
    for _, s in ipairs(comments[buf] or {}) do
      if lnum >= s.from and lnum <= s.to then
        local height = vim.api.nvim_win_text_height(win, { start_row = s.from, end_row = s.to, max_height = 2 }).all
        local corner = corners.middle
        if height == 1 then
          corner = corners.single
        elseif lnum == s.from and vnum == 0 then
          corner = corners.top
        elseif
          lnum == s.to
          and vnum == vim.api.nvim_win_text_height(win, { start_row = s.to, end_row = s.to }).all - 1
        then
          corner = corners.last
        end
        -- Show last corner when a closed fold encompasses the comment's last line
        if corner == corners.middle then
          local fold_end = vim.fn.foldclosedend(lnum + 1)
          if fold_end ~= -1 and (fold_end - 1) >= s.to then
            corner = corners.last
          end
        end
        return { text = corner, hl = s.dirty and "OctoDirty" or "OctoStatusColumn" }
      end
    end
  end
  return get_sign
end

---octo.ui.statuscolumn.get_sign を高速版に差し替える。
---@return boolean patched 差し替え済みならtrue
function M.setup()
  local ok, statuscolumn = pcall(require, "octo.ui.statuscolumn")
  if not ok or type(statuscolumn) ~= "table" or type(statuscolumn.get_sign) ~= "function" then
    return false
  end
  if statuscolumn._octo_perf_get_sign and statuscolumn.get_sign == statuscolumn._octo_perf_get_sign then
    return true
  end

  local comments, corners = find_upvalues(statuscolumn.get_sign)
  if type(comments) ~= "table" or type(corners) ~= "table" then
    return false
  end

  local get_sign = make_get_sign(comments, corners)
  statuscolumn.get_sign = get_sign
  statuscolumn._octo_perf_get_sign = get_sign
  return true
end

return M
