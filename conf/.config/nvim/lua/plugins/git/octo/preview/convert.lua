-- octo バッファのメタデータから markdown 行配列と anchor テーブルを生成する
-- 副作用なしの純関数として書き、テスト可能に保つ

local M = {}

-- 行内の HTML <img src="URL"> と markdown ![alt](URL) の URL を resolver で
-- 解決し、path が返ったら絶対 path のまま置換する。
-- mkdp の /_local_image_ ルートは絶対 path をそのまま fs.createReadStream に
-- 通すので、file:// prefix を付けないほうが読み込まれる。
-- また mkdp/markdown-it は ![alt](URL) の URL に file:// や絶対 path を
-- 通しづらいので、markdown img は HTML <img> に変換して渡す
-- resolver が nil を返した URL は素通し。
-- HTML img タグから width/height 属性を除去する。
-- 元の GitHub 添付画像は固定 width/height (`2386x1416` 等) を持っており、
-- max-width で幅が縮んでも height が固定のままだと aspect ratio が崩壊して
-- 縦潰れになるため。
local function strip_size_attrs(tag)
  tag = tag:gsub("%s+width=([\"'])[^\"']*%1", "")
  tag = tag:gsub("%s+height=([\"'])[^\"']*%1", "")
  return tag
end

local function replace_images(line, resolver)
  if not resolver then
    return line
  end
  -- HTML img: src="..." または src='...'
  line = line:gsub("<img[^>]*>", function(tag)
    local url = tag:match("src=[\"']([^\"']+)[\"']")
    if not url then
      return tag
    end
    local path = resolver(url)
    if not path then
      return tag
    end
    local new_tag = tag:gsub("(src=[\"'])[^\"']+([\"'])", function(pre, post)
      return pre .. path .. post
    end, 1)
    return strip_size_attrs(new_tag)
  end)
  -- markdown ![alt](URL) - URL 部分は括弧を含まないと仮定
  -- HTML <img> に変換して置換する。alt は "!%b[]" が `![alt]` を含む
  line = line:gsub("(!%b[])%(([^%s%)]+)%)", function(alt_bracket, url)
    local path = resolver(url)
    local alt = alt_bracket:sub(3, -2) -- ![alt] -> alt
    if path then
      return string.format('<img src="%s" alt="%s" />', path, alt)
    end
    return alt_bracket .. "(" .. url .. ")"
  end)
  return line
end

-- octo_buffer: _G.octo_buffers[bufnr] と同じ構造
--   node             { number, title }
--   titleMetadata    { startLine, endLine }  0-indexed
--   bodyMetadata     { startLine, endLine }  0-indexed inclusive
--   commentsMetadata [{ startLine, endLine, id }]
-- get_lines(start_0, end_exclusive_0) -> lines
--   nvim_buf_get_lines と同じシグネチャ（0-indexed, 終端は exclusive）
-- opts (optional):
--   resolve_image(url) -> local_path or nil
--     URL を local cache path に解決する関数
--
-- returns:
--   md      string[]                  shadow buffer に流し込む markdown 行
--   anchors table<octo_line, md_line> 1-indexed → 1-indexed の対応表
function M.build(octo_buffer, get_lines, opts)
  opts = opts or {}
  local resolver = opts.resolve_image
  local md = {}
  local anchors = {}

  local function push(line)
    md[#md + 1] = line
  end

  local function map_range(octo_start_0, octo_end_0)
    local lines = get_lines(octo_start_0, octo_end_0 + 1)
    for i, line in ipairs(lines) do
      push(replace_images(line, resolver))
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
