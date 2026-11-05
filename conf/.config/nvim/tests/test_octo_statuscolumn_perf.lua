package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local OCTO_SC = "octo.ui.statuscolumn"
local PERF = "plugins.git.octo.statuscolumn_perf"

-- octo.nvim の lua/octo/ui/statuscolumn.lua と同じ構造・ロジックのスタブ
local function upstream_statuscolumn()
  local corners = {
    top = "┌╴",
    middle = "│ ",
    last = "└╴",
    single = "[ ",
  }
  local comments = {}
  local M = {}

  function M.reset(buf)
    comments[buf] = nil
  end

  function M.add(bufnr, start_line, end_line, is_dirty)
    comments[bufnr] = comments[bufnr] or {}
    table.insert(comments[bufnr], { from = start_line, to = end_line, dirty = is_dirty })
  end

  function M.get_sign(buf, lnum, vnum, win)
    lnum = lnum - 1
    for _, s in ipairs(comments[buf] or {}) do
      if lnum >= s.from and lnum <= s.to then
        local height = vim.api.nvim_win_text_height(win, { start_row = s.from, end_row = s.to }).all
        local height_end = vim.api.nvim_win_text_height(win, { start_row = s.to, end_row = s.to }).all
        local corner = corners.middle
        if height == 1 then
          corner = corners.single
        elseif lnum == s.from and vnum == 0 then
          corner = corners.top
        elseif lnum == s.to and vnum == height_end - 1 then
          corner = corners.last
        end
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

  return M
end

local function reload_perf()
  package.loaded[PERF] = nil
  return require(PERF)
end

-- 1. octo.nvim が無い環境では何もしない
package.loaded[OCTO_SC] = nil
assert_eq(reload_perf().setup(), false, "octoが無いときはfalseを返す")

-- 2. 内部構造(comments/corners)が見つからないときは元の実装を残す
local changed = {
  get_sign = function()
    return nil
  end,
}
local changed_get_sign = changed.get_sign
package.loaded[OCTO_SC] = changed
assert_eq(reload_perf().setup(), false, "内部構造が違うときはfalseを返す")
assert_eq(changed.get_sign, changed_get_sign, "内部構造が違うときはget_signを差し替えない")

-- 3. 差し替え前後で全画面行の記号が一致する
local sc = upstream_statuscolumn()
package.loaded[OCTO_SC] = sc
local original_get_sign = sc.get_sign

vim.cmd("enew")
local win = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_get_current_buf()
vim.wo[win].wrap = true
vim.wo[win].linebreak = true
local long = string.rep("wrapped words ", 40) -- ウィンドウ幅を超えて折り返す
local lines = {}
for i = 1, 40 do
  lines[i] = (i % 3 == 0) and long or ("line " .. i)
end
lines[13] = long
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

-- 範囲は0始まり・両端含む（octoのsigns.place_signsと同じ）
sc.add(buf, 0, 0, false) -- 折り返さない1行 -> "[ "
sc.add(buf, 2, 10, true) -- 複数行・未保存 -> ┌╴│└╴ + OctoDirty
sc.add(buf, 12, 12, false) -- 折り返す1行 -> ┌╴ と └╴
sc.add(buf, 14, 20, false) -- 末尾が閉じたfoldに含まれる
sc.add(buf, 22, 24, false) -- 全体が1つの閉じたfoldに収まる -> "[ "
sc.add(buf, 26, 26, false) -- より大きな閉じたfoldの中の1行
vim.wo[win].foldmethod = "manual"
vim.cmd("16,21fold")
vim.cmd("23,25fold")
vim.cmd("26,30fold")

local function snapshot(get_sign)
  local result = {}
  for lnum = 1, #lines do
    local height = vim.api.nvim_win_text_height(win, { start_row = lnum - 1, end_row = lnum - 1 }).all
    for vnum = 0, math.max(0, height - 1) do
      local sign = get_sign(buf, lnum, vnum, win)
      table.insert(result, {
        key = lnum .. ":" .. vnum,
        value = sign and (sign.text .. "|" .. sign.hl) or "nil",
      })
    end
  end
  return result
end

local expected = snapshot(original_get_sign)

assert_eq(reload_perf().setup(), true, "octoがあるときはtrueを返す")
if sc.get_sign == original_get_sign then
  error("get_signが差し替えられていない")
end

local actual = snapshot(sc.get_sign)
assert_eq(#actual, #expected, "比較した画面行数")
local kinds = {}
for i, row in ipairs(expected) do
  assert_eq(actual[i].value, row.value, "記号の一致 (行:折り返し " .. row.key .. ")")
  local corner = row.value:match("^(.-)|")
  if corner then
    kinds[corner] = true
  end
end
for _, corner in ipairs({ "┌╴", "│ ", "└╴", "[ " }) do
  assert_eq(kinds[corner], true, "テストケースが " .. corner .. " を含む")
end

-- 4. 複数行の範囲の高さを最後まで数えない（長いコメントで重くなる原因）
local text_height = vim.api.nvim_win_text_height
local unbounded = 0
vim.api.nvim_win_text_height = function(w, opts)
  if opts and opts.start_row ~= opts.end_row and opts.max_height == nil then
    unbounded = unbounded + 1
  end
  return text_height(w, opts)
end
snapshot(sc.get_sign)
vim.api.nvim_win_text_height = text_height
assert_eq(unbounded, 0, "複数行の範囲を上限なしで数えた回数")

-- 5. 2回呼んでも差し替え済みの関数を保つ
local patched = sc.get_sign
assert_eq(require(PERF).setup(), true, "2回目もtrueを返す")
assert_eq(sc.get_sign, patched, "2回目は差し替え済みの関数を保つ")

print("octo statuscolumn perf tests passed")
