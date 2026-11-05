-- Agent ターミナルに最後に出た Markdown の絶対パスを探して開く。
--
-- Claude Code は長いパスを単語の途中で折り返し、続きの行を空白で字下げする。
--   "  /private/tmp/claude-501/-Users-happy-src-github-com-happy6"
--   "  63-dotfiles/.../scratchpa"
--   "  d/pr-body-draft.md"
-- そこで、行末まで続くパスは次の行（字下げを除く）とつないでから探す。
-- つないだ結果が本物の折り返しか偶然かは区別できないため、候補を複数作り、
-- 実在するファイルだけを採用する。
local M = {}

-- パスに使われる文字。%w はロケールによって UTF-8 の先頭バイトにも一致しうるので使わない。
local PATH_CHARS = "A-Za-z0-9%._%-/~+@"
local PATH_RUN = "^[" .. PATH_CHARS .. "]*"
local IS_PATH_CHAR = "[" .. PATH_CHARS .. "]"

local function rstrip(s)
  return (s:gsub("%s+$", ""))
end

local function lstrip(s)
  return (s:gsub("^%s+", ""))
end

local function default_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- 行の中で絶対パス（/ または ~/）が始まる位置を、右から順に返す。
-- 直前がパス文字の / は単語の途中（"6/scratchpad" など）なので開始位置にしない。
local function path_starts(line)
  local starts = {}
  for i = 1, #line do
    local c = line:sub(i, i)
    local is_start = c == "/" or (c == "~" and line:sub(i + 1, i + 1) == "/")
    if is_start and (i == 1 or not line:sub(i - 1, i - 1):match(IS_PATH_CHAR)) then
      table.insert(starts, 1, i)
    end
  end
  return starts
end

-- lines[i] の s 文字目から始まるパスを、折り返しを考慮してつなぐ。
-- 戻り値: つないだ文字列, つなぎ目（追加した各行の直前のバイト位置）の集合
local function join_from(lines, i, s)
  local text = rstrip(lines[i]:sub(s))
  local boundaries = {}
  local j = i
  while j < #lines and #text:match(PATH_RUN) == #text do
    j = j + 1
    local nxt = lstrip(rstrip(lines[j]))
    if nxt == "" then
      break
    end
    boundaries[#text] = true
    text = text .. nxt
  end
  return text, boundaries
end

-- つないだ文字列から .md で終わる候補を長い順に返す。
-- .md で切ってよいのは「パス文字の終わり（末尾の . は文の句点とみなす）」か「つなぎ目」だけ。
-- これにより /tmp/a.mdx から /tmp/a.md を作らない。
local function candidates(text, boundaries)
  local run = text:match(PATH_RUN)
  local run_end = #(run:gsub("%.+$", ""))
  local result = {}
  for k = #run, 3, -1 do
    if run:sub(k - 2, k) == ".md" and (k == run_end or boundaries[k]) then
      local line = nil
      if k == #run then
        line = tonumber(text:sub(k + 1):match("^:(%d+)"))
      end
      table.insert(result, { path = run:sub(1, k), line = line })
    end
  end
  return result
end

local function expand(path)
  if path:sub(1, 2) == "~/" then
    return vim.fn.expand("~") .. path:sub(2)
  end
  return path
end

-- lines の下から探し、実在する最後の .md パスと行番号（無ければ nil）を返す。
function M.find_last(lines, exists)
  exists = exists or default_exists
  for i = #lines, 1, -1 do
    for _, s in ipairs(path_starts(lines[i])) do
      local text, boundaries = join_from(lines, i, s)
      for _, cand in ipairs(candidates(text, boundaries)) do
        local path = expand(cand.path)
        if exists(path) then
          return path, cand.line
        end
      end
    end
  end
  return nil
end

-- buf の内容から探したパスを開く。見つかれば true。
-- Agent タブでは作業タブで開く。Agent タブで分割を作ると routing の自動移送が
-- 分割をターミナルに戻して残し、カーソルも移送前の位置（1行目）で上書きするため。
-- それ以外のタブでは縦分割で開く。
function M.open_last(buf)
  if buf == nil or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local path, line = M.find_last(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  if not path then
    vim.notify("Markdown のパスが見つかりません", vim.log.levels.WARN)
    return false
  end
  if require("agent_term.local.state").is_agent_tabpage(0) then
    local bufnr = vim.fn.bufadd(path)
    vim.bo[bufnr].buflisted = true
    require("agent_term.local.routing").open_buf_in_work_tab(bufnr, line and { line, 0 } or nil)
    return true
  end
  vim.cmd("vsplit " .. vim.fn.fnameescape(path))
  if line then
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  end
  return true
end

return M
