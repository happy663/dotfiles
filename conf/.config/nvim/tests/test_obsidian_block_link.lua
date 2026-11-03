local config = vim.fn.getcwd() .. "/conf/.config/nvim"
package.path = config .. "/lua/?.lua;" .. package.path

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

-- テスト実行でシステムのクリップボードを上書きしないよう、setreg と notify を記録用に差し替える
local registers, notifications
vim.fn.setreg = function(name, value)
  registers[name] = value
end
vim.notify = function(msg, level)
  table.insert(notifications, { msg = msg, level = level })
end

local block_link = require("utils.obsidian-block-link")

local function note_buffer(name, lines, cursor)
  registers, notifications = {}, {}
  vim.cmd("enew!")
  if name then
    vim.api.nvim_buf_set_name(0, "/tmp/vault/daily/" .. name .. ".md")
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
end

local function line_at(row)
  return vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
end

local function fixed_id(id)
  return {
    gen_id = function()
      return id
    end,
  }
end

local function never_gen_id()
  return {
    gen_id = function()
      error("既存IDや見出しの行ではIDを生成しない")
    end,
  }
end

-- 通常の行: 行末にIDを付け、ブロックリンクを + と " にコピーする
note_buffer("2026-11-04", { "# 見出し", "", "参照したい行" }, { 3, 3 })
local link = block_link.copy(fixed_id("abc123"))
assert_eq(link, "[[2026-11-04#^abc123]]", "ノート名とIDでブロックリンクを作る")
assert_eq(line_at(3), "参照したい行 ^abc123", "行末にブロックIDを付ける")
assert_eq(registers["+"], "[[2026-11-04#^abc123]]", "システムクリップボードにコピーする")
assert_eq(
  registers['"'],
  "[[2026-11-04#^abc123]]",
  "無名レジスタにもコピーしてpで貼れるようにする"
)
assert_eq(vim.api.nvim_win_get_cursor(0)[2], 3, "カーソル位置を動かさない")

-- 末尾の空白: 空白を詰めてからIDを付ける
note_buffer("trailing", { "末尾に空白  " }, { 1, 0 })
block_link.copy(fixed_id("abc123"))
assert_eq(line_at(1), "末尾に空白 ^abc123", "末尾の空白を詰めてIDを付ける")

-- リスト項目: そのまま末尾にIDを付ける
note_buffer("list", { "- タスク" }, { 1, 0 })
assert_eq(block_link.copy(fixed_id("abc123")), "[[list#^abc123]]", "リスト項目もブロックリンクにする")
assert_eq(line_at(1), "- タスク ^abc123", "リスト項目の末尾にIDを付ける")

-- 既存ID: 行は変えず、既存のIDを使う
note_buffer("existing", { "既存の行 ^existing-id" }, { 1, 0 })
assert_eq(block_link.copy(never_gen_id()), "[[existing#^existing-id]]", "既存のIDでリンクを作る")
assert_eq(line_at(1), "既存の行 ^existing-id", "既存IDのある行は変更しない")

-- 見出し: IDは付けず、見出しリンクにする
note_buffer("heading", { "## 見出しテキスト" }, { 1, 0 })
assert_eq(
  block_link.copy(never_gen_id()),
  "[[heading#見出しテキスト]]",
  "見出し行は見出しリンクにする"
)
assert_eq(line_at(1), "## 見出しテキスト", "見出し行は変更しない")

-- 空行: 何もせず警告する
note_buffer("blank", { "   " }, { 1, 0 })
assert_eq(block_link.copy(never_gen_id()), nil, "空行ではリンクを作らない")
assert_eq(line_at(1), "   ", "空行は変更しない")
assert_eq(registers["+"], nil, "空行ではクリップボードを変更しない")
assert_eq(notifications[1] and notifications[1].level, vim.log.levels.WARN, "空行では警告する")

-- 無名バッファ: ノート名がないので何もせず警告する
note_buffer(nil, { "テキスト" }, { 1, 0 })
assert_eq(block_link.copy(never_gen_id()), nil, "無名バッファではリンクを作らない")
assert_eq(line_at(1), "テキスト", "無名バッファの行は変更しない")
assert_eq(notifications[1] and notifications[1].level, vim.log.levels.WARN, "無名バッファでは警告する")

-- 既定のID生成: Obsidian アプリと同じ英小文字と数字の6文字
local id1, id2 = block_link.generate_id(), block_link.generate_id()
assert_eq(id1:match("^[a-z0-9]+$") ~= nil and #id1 == 6, true, "IDは英小文字と数字の6文字")
assert_eq(id1 ~= id2, true, "呼ぶたびに違うIDを作る")

print("obsidian block link tests passed")
