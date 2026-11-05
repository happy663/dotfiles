package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local open_md = require("agent_term.open_md")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

-- 存在するファイルの集合を渡して exists 関数を作る（ファイルシステムに依存しない）
local function exists_in(set)
  local lookup = {}
  for _, path in ipairs(set) do
    lookup[path] = true
  end
  return function(path)
    return lookup[path] == true
  end
end

local P = "/private/tmp/claude-501/-Users-happy-src-github-com-happy663-dotfiles/"
  .. "e73129ab-e6a7-4eaa-bb38-67a2baadc356/scratchpad/pr-body-draft.md"
local exists_p = exists_in({ P })

local function find(lines, exists)
  return open_md.find_last(lines, exists or exists_p)
end

-- 1. 1行に収まるパス
assert_eq(
  find({ "⏺ 下書きは /tmp/a.md に置きました。" }, exists_in({ "/tmp/a.md" })),
  "/tmp/a.md",
  "1行に収まるパス"
)

-- 2. 本文中で折り返される（Claude Code 幅60桁の実表示。続きの行は空白2つ）
assert_eq(
  find({
    "⏺ 下書きは /private/tmp/claude-501/-Users-happy-src-github-c",
    "  om-happy663-dotfiles/e73129ab-e6a7-4eaa-bb38-67a2baadc356/",
    "  scratchpad/pr-body-draft.md に置きました。",
  }),
  P,
  "本文中で3行に折り返されたパス"
)

-- 3. パスだけの行が単語の途中で折り返される
assert_eq(
  find({
    "  /private/tmp/claude-501/-Users-happy-src-github-com-happy6",
    "  63-dotfiles/e73129ab-e6a7-4eaa-bb38-67a2baadc356/scratchpa",
    "  d/pr-body-draft.md",
  }),
  P,
  "単語の途中で折り返されたパス"
)

-- 4. リスト項目の折り返し（続きの行は空白4つ）
assert_eq(
  find({
    "  - /private/tmp/claude-501/-Users-happy-src-github-com-happ",
    "    y663-dotfiles/e73129ab-e6a7-4eaa-bb38-67a2baadc356/scrat",
    "    chpad/pr-body-draft.md",
  }),
  P,
  "リスト項目内で折り返されたパス"
)

-- 5. 全角括弧で囲まれ、括弧の直後に文が続く
assert_eq(
  find({
    "    下書き（/private/tmp/claude-501/-Users-happy-src-github-",
    "    com-happy663-dotfiles/e73129ab-e6a7-4eaa-bb38-67a2baadc3",
    "    56/scratchpad/pr-body-draft.md）を確認して。",
  }),
  P,
  "全角括弧で囲まれたパス"
)

-- 6. 行番号付き（path:12）は行番号も返す
do
  local path, line = find({
    "    /private/tmp/claude-501/-Users-happy-src-github-com-happ",
    "    y663-dotfiles/e73129ab-e6a7-4eaa-bb38-67a2baadc356/scrat",
    "    chpad/pr-body-draft.md:12",
  })
  assert_eq(path, P, "行番号付きのパス")
  assert_eq(line, 12, "行番号を取り出す")
end
do
  local _, line = find({ "  " .. P })
  assert_eq(line, nil, "行番号が無ければ nil")
end

-- 7. 複数あれば一番下（最後に出たもの）を選ぶ
assert_eq(
  find({ "  /tmp/old.md を作成", "  次に /tmp/new.md を作成" }, exists_in({ "/tmp/old.md", "/tmp/new.md" })),
  "/tmp/new.md",
  "複数行なら一番下の行"
)
assert_eq(
  find({ "  /tmp/old.md と /tmp/new.md" }, exists_in({ "/tmp/old.md", "/tmp/new.md" })),
  "/tmp/new.md",
  "同じ行なら右側"
)

-- 8. 一番下が存在しないファイルなら、その上の存在するものを選ぶ
assert_eq(
  find({ "  /tmp/real.md を作成", "  /tmp/body.md は削除済み" }, exists_in({ "/tmp/real.md" })),
  "/tmp/real.md",
  "存在しないパスは飛ばす"
)

-- 9. 行末でたまたま終わったパスの次の行が英字で始まっても、結合で壊れない
assert_eq(
  find({ "  see /tmp/a.md", "  and more text" }, exists_in({ "/tmp/a.md" })),
  "/tmp/a.md",
  "次の行の英字を結合しても元のパスを拾う"
)

-- 10. 行末で終わったパスの次の行がリスト記号やパスで始まっても壊れない
assert_eq(
  find({ "  /tmp/a.md", "  - /tmp/b.txt" }, exists_in({ "/tmp/a.md" })),
  "/tmp/a.md",
  "次の行のリスト記号を結合しても元のパスを拾う"
)
assert_eq(
  find({ "  /tmp/a.md", "  /tmp/b.md" }, exists_in({ "/tmp/a.md" })),
  "/tmp/a.md",
  "次の行のパス（存在しない）を結合しても元のパスを拾う"
)

-- 11. 相対パス・ファイル名だけは対象外
assert_eq(
  find({ "  README.md と docs/guide.md を更新" }, exists_in({ "README.md", "docs/guide.md" })),
  nil,
  "相対パスは対象外"
)

-- 12. 単語の途中の / から始まる部分はパスとして扱わない
assert_eq(
  find({ "  6/scratchpad/x.md" }, exists_in({ "/scratchpad/x.md" })),
  nil,
  "直前がパス文字の / は開始位置にしない"
)

-- 13. 存在しないパスしか無ければ nil
assert_eq(find({ "  /tmp/none.md" }, exists_in({})), nil, "存在しなければ nil")
assert_eq(find({}, exists_in({})), nil, "空バッファは nil")

-- 14. ~/ から始まるパスは展開して扱う
do
  local expanded = vim.fn.expand("~") .. "/notes/draft.md"
  assert_eq(find({ "  ~/notes/draft.md を見て" }, exists_in({ expanded })), expanded, "~/ を展開")
end

-- 15. 折り返し行の末尾に空白が残っていても結合する
assert_eq(
  find({
    "  /private/tmp/claude-501/-Users-happy-src-github-com-happy6   ",
    "  63-dotfiles/e73129ab-e6a7-4eaa-bb38-67a2baadc356/scratchpa",
    "  d/pr-body-draft.md",
  }),
  P,
  "行末の空白を無視して結合"
)

-- 16. .md 以外（.mdx, .md.bak）は対象外。.md の部分だけを拾うことはしない
assert_eq(find({ "  /tmp/a.mdx" }, exists_in({ "/tmp/a.md", "/tmp/a.mdx" })), nil, ".mdx は対象外")

-- 17. 英文の句読点が直後に付いても拾う
assert_eq(find({ "  see /tmp/a.md." }, exists_in({ "/tmp/a.md" })), "/tmp/a.md", "末尾のピリオドを除く")
assert_eq(find({ "  /tmp/a.md, /tmp/b.txt" }, exists_in({ "/tmp/a.md" })), "/tmp/a.md", "末尾のカンマを除く")

-- open: 通常バッファの内容から探して、縦分割で開き、行番号へ移動する
do
  local tmp = vim.fn.tempname() .. ".md"
  vim.fn.writefile({ "l1", "l2", "l3" }, tmp)
  vim.cmd("enew")
  local src = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(src, 0, -1, false, { "⏺ 下書きは " .. tmp .. ":2 に置きました。" })
  local wins_before = #vim.api.nvim_tabpage_list_wins(0)
  assert_eq(open_md.open_last(src), true, "見つかれば true")
  assert_eq(vim.fn.resolve(vim.api.nvim_buf_get_name(0)), vim.fn.resolve(tmp), "見つけたファイルを開く")
  assert_eq(#vim.api.nvim_tabpage_list_wins(0), wins_before + 1, "縦分割で開く")
  assert_eq(vim.api.nvim_win_get_cursor(0)[1], 2, "行番号へ移動")
  vim.cmd("only")
end
do
  vim.cmd("enew")
  local src = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(src, 0, -1, false, { "パスなし" })
  assert_eq(open_md.open_last(src), false, "見つからなければ false")
  assert_eq(vim.api.nvim_get_current_buf(), src, "見つからなければ何も開かない")
end

-- open: Agent タブからは作業タブで開き、Agent タブに分割を残さない
-- （routing の自動移送と同じ移り先にしつつ、行番号へも移動する）
do
  local routing = require("agent_term.local.routing")
  routing.setup()
  vim.cmd("tabonly")
  vim.cmd("only")
  local work_tab = vim.api.nvim_get_current_tabpage()

  local tmp = vim.fn.tempname() .. ".md"
  vim.fn.writefile({ "l1", "l2", "l3" }, tmp)
  local text = vim.fn.tempname() .. ".txt"
  vim.fn.writefile({ "⏺ 下書きは " .. tmp .. ":2 に置きました。" }, text)

  vim.cmd("tabnew")
  vim.t.agent_pure = true
  local agent_tab = vim.api.nvim_get_current_tabpage()
  local term_buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen({ "cat", text })
  vim.t.agent_terminal_bufnr = term_buf
  vim.wait(2000, function()
    return table.concat(vim.api.nvim_buf_get_lines(term_buf, 0, -1, false)):find("置きました") ~= nil
  end)
  vim.api.nvim_set_current_tabpage(work_tab)
  vim.api.nvim_set_current_tabpage(agent_tab)

  assert_eq(open_md.open_last(term_buf), true, "Agentタブ: 見つかれば true")
  vim.wait(200)

  assert_eq(vim.api.nvim_get_current_tabpage(), work_tab, "Agentタブ: 作業タブへ移る")
  assert_eq(vim.fn.resolve(vim.api.nvim_buf_get_name(0)), vim.fn.resolve(tmp), "Agentタブ: 作業タブで開く")
  assert_eq(vim.api.nvim_win_get_cursor(0)[1], 2, "Agentタブ: 行番号へ移動")
  assert_eq(#vim.api.nvim_tabpage_list_wins(agent_tab), 1, "Agentタブ: 分割を残さない")
  assert_eq(
    vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_list_wins(agent_tab)[1]),
    term_buf,
    "Agentタブ: ターミナルはそのまま"
  )

  vim.api.nvim_set_current_tabpage(agent_tab)
  vim.cmd("tabclose")
  vim.cmd("only")
end

-- Agent terminal に gm が付く
do
  local nav = require("agent_term.message_nav")
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  local job = vim.fn.termopen("cat")
  nav.attach(buf, "claude")
  assert_eq(vim.fn.maparg("gm", "n", false, true).desc, "open last markdown path", "Claudeにgmを登録")
  vim.fn.jobstop(job)
  vim.api.nvim_buf_delete(buf, { force = true })
end

print("test_agent_term_open_md: OK")
