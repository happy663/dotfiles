package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local cleanup = require("utils.lazygit_cleanup")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function scratch(filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = filetype or ""
  return buf
end

local function open_float(buf)
  return vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 10,
    height = 3,
  })
end

-- Agent タブ相当: 名前付きのメインウィンドウを no-neck-pain の余白（名前が空の分割）で挟む
vim.cmd("tabnew")
local tabpage = vim.api.nvim_get_current_tabpage()
local main_win = vim.api.nvim_get_current_win()
vim.api.nvim_buf_set_name(vim.api.nvim_get_current_buf(), "agent-main")

vim.cmd("leftabove vsplit")
local left_pad = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(left_pad, scratch("no-neck-pain"))
vim.api.nvim_set_current_win(main_win)
vim.cmd("rightbelow vsplit")
local right_pad = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(right_pad, scratch("no-neck-pain"))
vim.api.nvim_set_current_win(main_win)

local lazygit_float = open_float(scratch("lazygit"))
local cmp_float = open_float(scratch("cmp_menu"))
local unnamed_float = open_float(scratch(""))

local main_width_before = vim.api.nvim_win_get_width(main_win)

cleanup.cleanup(tabpage)

-- 1. 分割ウィンドウ（no-neck-pain の余白）は名前が空でも閉じない
assert_eq(vim.api.nvim_win_is_valid(left_pad), true, "左の余白ウィンドウは残る")
assert_eq(vim.api.nvim_win_is_valid(right_pad), true, "右の余白ウィンドウは残る")

-- 2. メインウィンドウの幅が変わらない（=ターミナルに SIGWINCH が飛ばない）
assert_eq(vim.api.nvim_win_get_width(main_win), main_width_before, "メインウィンドウの幅は変わらない")

-- 3. 掃除対象のフロートは閉じる
assert_eq(vim.api.nvim_win_is_valid(lazygit_float), false, "lazygit のフロートは閉じる")
assert_eq(vim.api.nvim_win_is_valid(cmp_float), false, "cmp_menu のフロートは閉じる")
assert_eq(vim.api.nvim_win_is_valid(unnamed_float), false, "名前が空のフロートは閉じる")

-- 4. 他タブのウィンドウには触れない
vim.cmd("tabnew")
local other_tab = vim.api.nvim_get_current_tabpage()
local other_float = open_float(scratch("lazygit"))
cleanup.cleanup(tabpage)
assert_eq(vim.api.nvim_win_is_valid(other_float), true, "別タブのフロートは閉じない")
cleanup.cleanup(other_tab)
assert_eq(vim.api.nvim_win_is_valid(other_float), false, "対象タブのフロートは閉じる")

print("test_lazygit_cleanup: ALL PASSED")
