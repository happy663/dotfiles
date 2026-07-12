-- octo バッファのメタデータから markdown 行配列と anchor テーブルを生成する
-- 副作用なしの純関数として書き、テスト可能に保つ

local M = {}

-- octo_buffer: _G.octo_buffers[bufnr] と同じ構造
--   node             { number, title }
--   titleMetadata    { startLine, endLine }  0-indexed
--   bodyMetadata     { startLine, endLine }  0-indexed inclusive
--   commentsMetadata [{ startLine, endLine, id }]
-- get_lines(start_0, end_exclusive_0) -> lines
--   nvim_buf_get_lines と同じシグネチャ（0-indexed, 終端は exclusive）
--
-- returns:
--   md      string[]                  shadow buffer に流し込む markdown 行
--   anchors table<octo_line, md_line> 1-indexed → 1-indexed の対応表
function M.build(octo_buffer, get_lines)
  local md = {}
  local anchors = {}

  local function push(line)
    md[#md + 1] = line
  end

  local function map_range(octo_start_0, octo_end_0)
    local lines = get_lines(octo_start_0, octo_end_0 + 1)
    for i, line in ipairs(lines) do
      push(line)
      -- octo 側は 1-indexed で持ちたい（fixture もそう）
      local octo_line_1 = octo_start_0 + i
      anchors[octo_line_1] = #md
    end
  end

  local title = (octo_buffer.node and octo_buffer.node.title) or "(untitled)"
  push("# " .. title)

  local body = octo_buffer.bodyMetadata
  if body and body.startLine and body.endLine and body.endLine >= body.startLine then
    push("")
    map_range(body.startLine, body.endLine)
  end

  local comments = octo_buffer.commentsMetadata or {}
  for i, cm in ipairs(comments) do
    if cm.startLine and cm.endLine and cm.endLine >= cm.startLine then
      push("")
      push("---")
      push("")
      local is_draft = cm.id == -1 or cm.id == "-1"
      if is_draft then
        push("### New comment (draft)")
      else
        push(string.format("### Comment #%d", i))
      end
      push("")
      map_range(cm.startLine, cm.endLine)
    end
  end

  return md, anchors
end

return M
