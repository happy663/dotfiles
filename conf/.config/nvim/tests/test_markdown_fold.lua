local config = vim.fn.getcwd() .. "/conf/.config/nvim"
package.path = config .. "/lua/?.lua;" .. package.path

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function markdown_buffer(lines)
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "markdown"
  -- Octo未ロード・通常設定で全展開の状態からMarkdown設定だけを適用する。
  vim.opt_local.foldmethod = "manual"
  vim.opt_local.foldenable = true
  vim.opt_local.foldlevel = 99
  dofile(config .. "/after/ftplugin/markdown.lua")
  vim.cmd("normal! zX")
end

markdown_buffer({
  "本文",
  "<details>",
  "<summary>調査ログ</summary>",
  "詳細の内容",
  "</details>",
  "続き",
})
assert_eq(vim.wo.foldmethod, "expr", "Markdownで式ベースのfoldを使う")
assert_eq(vim.wo.foldlevel, 0, "初期状態でfoldを閉じる")
assert_eq(vim.fn.foldclosed(1), -1, "detailsより前の本文は折りたたまない")
assert_eq(vim.fn.foldclosed(2), 2, "Octo未ロードでもdetailsを折りたたむ")
assert_eq(vim.fn.foldclosedend(2), 5, "detailsの閉じタグまで折りたたむ")
assert_eq(vim.fn.foldtextresult(2), "  調査ログ ", "summaryを折りたたみ表示に使う")
assert_eq(vim.fn.foldclosed(6), -1, "detailsより後の本文は折りたたまない")
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd("normal! za")
assert_eq(vim.fn.foldclosed(2), -1, "zaでdetailsを展開できる")
vim.cmd("normal! za")
assert_eq(vim.fn.foldclosed(2), 2, "zaでdetailsを閉じられる")

markdown_buffer({ "<details>", "内容", "</details>" })
assert_eq(vim.fn.foldtextresult(1), "  詳細 ", "summaryがなければ既定ラベルを表示する")

for _, count in ipairs({ 19, 20 }) do
  local lines = { "```lua" }
  for _ = 1, count do
    table.insert(lines, "print('test')")
  end
  table.insert(lines, "```")
  table.insert(lines, "本文")
  markdown_buffer(lines)
  if count == 19 then
    assert_eq(vim.fn.foldclosed(1), -1, "19行のコードブロックは折りたたまない")
  else
    assert_eq(vim.fn.foldclosed(1), 1, "20行のコードブロックはOctoと同様に折りたたむ")
    assert_eq(vim.fn.foldclosedend(1), 22, "コードブロックの閉じフェンスまで折りたたむ")
    assert_eq(
      vim.fn.foldtextresult(1),
      "  lua (20 lines) .......................................",
      "コードブロックは言語と行数を表示する"
    )
  end
  assert_eq(vim.fn.foldclosed(#lines), -1, "コードブロックより後の本文は折りたたまない")
end

assert_eq(package.loaded.octo, nil, "Octoプラグイン本体のロードを必要としない")
print("markdown fold tests passed")
