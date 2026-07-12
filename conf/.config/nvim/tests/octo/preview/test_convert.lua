-- test_convert.lua
-- octo -> markdown 変換関数のテスト
-- 使い方: nvim --headless -l tests/octo/preview/test_convert.lua

package.path = package.path
  .. ";./conf/.config/nvim/lua/?.lua"
  .. ";./conf/.config/nvim/lua/?/init.lua"
  .. ";./conf/.config/nvim/?.lua"
  .. ";./conf/.config/nvim/?/init.lua"

local convert = require("plugins.git.octo.preview.convert")

local total = 0
local failed = 0

local function assert_eq(name, actual, expected)
  total = total + 1
  local ok = actual == expected
  if not ok then
    failed = failed + 1
    io.write(string.format("[FAIL] %s\n  expected: %s\n  actual:   %s\n", name, tostring(expected), tostring(actual)))
  else
    io.write(string.format("[PASS] %s\n", name))
  end
end

-- lines テーブル（sparse な 1-indexed）から get_lines(start, end_exclusive) を作る
-- octo.nvim の nvim_buf_get_lines は 0-indexed
local function make_get_lines(fixture)
  return function(start_0, end_exclusive_0)
    local lines = {}
    -- 0-indexed row を 1-indexed に変換して fixture.lines を引く
    for row_0 = start_0, end_exclusive_0 - 1 do
      local row_1 = row_0 + 1
      table.insert(lines, fixture.lines[row_1] or "")
    end
    return lines
  end
end

-- ====================================================
-- Test 1: 空の fixture
-- ====================================================
do
  local input = {
    octo_buffer = {
      node = { number = 1, title = "Empty" },
      titleMetadata = { startLine = 0, endLine = 0 },
      bodyMetadata = { startLine = 2, endLine = 2 },
      commentsMetadata = {},
    },
    get_lines = function()
      return { "" }
    end,
  }
  local md, anchors = convert.build(input.octo_buffer, input.get_lines)
  assert_eq("empty: first md line is title", md[1], "# Empty")
  assert_eq("empty: anchor table is a table", type(anchors), "table")
end

-- ====================================================
-- Test 2: issue #279 (実データ)
-- ====================================================
do
  local fixture = require("tests.octo.preview.fixtures.issue_279")
  local md, anchors = convert.build(fixture.octo_buffer, make_get_lines(fixture))

  -- md はテーブル
  assert_eq("279: md is table", type(md), "table")
  assert_eq("279: anchors is table", type(anchors), "table")

  -- 先頭が # + title
  assert_eq(
    "279: md[1] is title heading",
    md[1],
    "# ターミナル内でのビューを快適にする方法を摸索する"
  )

  -- body の最初の行が md のどこかに出現する
  local body_first = "ターミナルやNeovimの設定を調整して、人間が見た時の負荷を下げたい"
  local found_body = false
  for _, line in ipairs(md) do
    if line == body_first then
      found_body = true
      break
    end
  end
  assert_eq("279: body first line present in md", found_body, true)

  -- comment 1 の本文 (line 28) の内容が md のどこかに出現する
  local c1 = "以下を導入した"
  local found_c1 = false
  for _, line in ipairs(md) do
    if line == c1 then
      found_c1 = true
      break
    end
  end
  assert_eq("279: comment 1 body present in md", found_c1, true)

  -- anchor: octo 15 (body 1行目) は md 上のどこか本文行にマップされる
  local body_anchor = anchors[15]
  assert_eq("279: anchor for body line exists", type(body_anchor), "number")
  assert_eq("279: anchor[15] points to body first line", md[body_anchor], body_first)

  -- anchor: octo 28 (comment 1 の最初の本文行) → md のどこかを指す
  local c1_anchor = anchors[28]
  assert_eq("279: anchor for comment 1 first line exists", type(c1_anchor), "number")
  assert_eq("279: anchor[28] points to '以下を導入した'", md[c1_anchor], c1)

  -- anchor: octo 15 と 16 は隣接しているので shadow でも隣接する
  local a15 = anchors[15]
  local a16 = anchors[16]
  assert_eq("279: body lines are contiguous in shadow", a16 - a15, 1)

  -- コメント境界には見出し行が挿入されている（--- + ### Comment のいずれか）
  local has_hr, has_comment_heading = false, false
  for _, line in ipairs(md) do
    if line == "---" then
      has_hr = true
    end
    if line:match("^### ") then
      has_comment_heading = true
    end
  end
  assert_eq("279: horizontal rule inserted", has_hr, true)
  assert_eq("279: comment heading inserted", has_comment_heading, true)

  -- comment 1 の最初の行の anchor は、その直前のいずれかが '###' or '---' である（見出しの後）
  local a_c1 = anchors[28]
  -- 見出しの直後は空行なので、遡って何行か検索
  local heading_nearby = false
  for i = math.max(1, a_c1 - 5), a_c1 - 1 do
    if md[i] and md[i]:match("^### ") then
      heading_nearby = true
      break
    end
  end
  assert_eq("279: heading precedes comment 1 body", heading_nearby, true)
end

-- ====================================================
-- Test 3: draft コメント（id = -1）の見出しは異なる
-- ====================================================
do
  local input = {
    node = { number = 1, title = "T" },
    titleMetadata = { startLine = 0, endLine = 0 },
    bodyMetadata = { startLine = 2, endLine = 2 },
    commentsMetadata = {
      { startLine = 5, endLine = 6, id = -1 },
    },
  }
  local get_lines = function(s, e)
    local lines = {}
    for row_0 = s, e - 1 do
      local row_1 = row_0 + 1
      if row_1 == 6 then
        lines[#lines + 1] = "draft body line 1"
      elseif row_1 == 7 then
        lines[#lines + 1] = "draft body line 2"
      else
        lines[#lines + 1] = ""
      end
    end
    return lines
  end
  local md, _ = convert.build(input, get_lines)
  local has_draft = false
  for _, line in ipairs(md) do
    if line:match("[Dd]raft") then
      has_draft = true
      break
    end
  end
  assert_eq("draft: heading contains 'draft'", has_draft, true)
end

-- ====================================================
-- Test 4: image resolver で HTML <img src="URL"> を file:// に置換
-- ====================================================
do
  local input = {
    node = { number = 1, title = "T" },
    titleMetadata = { startLine = 0, endLine = 0 },
    bodyMetadata = { startLine = 2, endLine = 2 },
    commentsMetadata = {},
  }
  local html_line =
    '<img width="100" alt="X" src="https://private-user-images.githubusercontent.com/123/abc.png?jwt=xxx" />'
  local get_lines = function(s, e)
    local lines = {}
    for row_0 = s, e - 1 do
      local row_1 = row_0 + 1
      if row_1 == 3 then
        lines[#lines + 1] = html_line
      else
        lines[#lines + 1] = ""
      end
    end
    return lines
  end
  local resolve_image = function(url)
    if url:match("private%-user%-images") then
      return "/tmp/cache/foo.png"
    end
    return nil
  end
  local md, _ = convert.build(input, get_lines, { resolve_image = resolve_image })
  -- 置換された画像行を確認
  local replaced = nil
  for _, line in ipairs(md) do
    if line:find("<img", 1, true) then
      replaced = line
      break
    end
  end
  assert_eq("img: html img line preserved", type(replaced), "string")
  if replaced then
    assert_eq("img: original URL removed", replaced:find("private%-user%-images"), nil)
    assert_eq("img: local path inserted", not not replaced:find("/tmp/cache/foo.png", 1, true), true)
  end
end

-- ====================================================
-- Test 5: image resolver で markdown ![alt](URL) を file:// に置換
-- ====================================================
do
  local input = {
    node = { number = 1, title = "T" },
    titleMetadata = { startLine = 0, endLine = 0 },
    bodyMetadata = { startLine = 2, endLine = 2 },
    commentsMetadata = {},
  }
  local md_img_line = "![screenshot](https://github.com/user-attachments/assets/68c802ac-72aa-4868-8a3a-673d208b860d)"
  local get_lines = function(s, e)
    local lines = {}
    for row_0 = s, e - 1 do
      local row_1 = row_0 + 1
      if row_1 == 3 then
        lines[#lines + 1] = md_img_line
      else
        lines[#lines + 1] = ""
      end
    end
    return lines
  end
  local resolve_image = function(_)
    return "/tmp/cache/bar.jpg"
  end
  local md, _ = convert.build(input, get_lines, { resolve_image = resolve_image })
  -- markdown img は HTML <img> に変換される
  local replaced = nil
  for _, line in ipairs(md) do
    if line:find("<img", 1, true) then
      replaced = line
      break
    end
  end
  assert_eq("md-img: converted to html img", type(replaced), "string")
  if replaced then
    assert_eq("md-img: original URL removed", replaced:find("user%-attachments"), nil)
    assert_eq("md-img: local path inserted", not not replaced:find("/tmp/cache/bar.jpg", 1, true), true)
    assert_eq("md-img: alt preserved", not not replaced:find('alt="screenshot"', 1, true), true)
  end
end

-- ====================================================
-- Test 6: resolver が nil を返す URL は素通し
-- ====================================================
do
  local input = {
    node = { number = 1, title = "T" },
    titleMetadata = { startLine = 0, endLine = 0 },
    bodyMetadata = { startLine = 2, endLine = 2 },
    commentsMetadata = {},
  }
  local original = "![x](https://example.com/foo.png)"
  local get_lines = function(s, e)
    local lines = {}
    for row_0 = s, e - 1 do
      local row_1 = row_0 + 1
      if row_1 == 3 then
        lines[#lines + 1] = original
      else
        lines[#lines + 1] = ""
      end
    end
    return lines
  end
  local resolve_image = function(_)
    return nil
  end
  local md, _ = convert.build(input, get_lines, { resolve_image = resolve_image })
  local passthrough = nil
  for _, line in ipairs(md) do
    if line:find("!%[") then
      passthrough = line
      break
    end
  end
  assert_eq("passthrough: line preserved", passthrough, original)
end

-- ====================================================
-- サマリ
-- ====================================================
io.write(string.format("\n=== %d / %d passed ===\n", total - failed, total))
os.exit(failed == 0 and 0 or 1)
