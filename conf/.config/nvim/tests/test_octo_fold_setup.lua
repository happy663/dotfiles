package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local fold = require("plugins.git.octo.fold")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "本文",
  "<details>",
  "<summary>ログ</summary>",
  "",
  "中身",
  "</details>",
  "末尾",
})

fold.setup_window_folds()
assert_eq(vim.wo.foldmethod, "expr", "foldmethodをexprにする")
assert_eq(vim.wo.foldexpr, "v:lua.require('plugins.git.octo.fold').octo_fold_all()", "foldexprを設定する")
assert_eq(vim.wo.foldtext, "v:lua.require('plugins.git.octo.fold').octo_foldtext()", "foldtextを設定する")
assert_eq(vim.wo.foldlevel, 0, "foldlevelを0にする")
assert_eq(vim.fn.foldclosed(2), 2, "初回はdetailsを閉じた状態にする")

-- detailsを開いてから、BufEnterによるFileType再発火を想定して再度呼ぶ
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd("normal! zo")
assert_eq(vim.fn.foldclosed(2), -1, "zoでdetailsが開く")

fold.setup_window_folds()
assert_eq(vim.fn.foldclosed(2), -1, "再度呼んでも開いたdetailsは閉じない")

print("octo fold setup tests passed")
