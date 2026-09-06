-- tmux の全ペインから Agent が乗っているものを集める。
-- 状態は #315 で導入した @agent-status（blocked / idle / running / error）を読む。
local M = {}

-- 一覧に出す順序。数値が小さいほど上。
local STATUS_RANK = {
  blocked = 1,
  idle = 2,
  running = 4,
}
-- running のまま一定時間更新されていないペイン。idle と running の間に置く。
local STALE_RANK = 3
local UNKNOWN_RANK = 5

-- Claude Code には中断用のフックが無く、Esc で応答を止めると状態が running のまま
-- 固まる（#315 の @agent-status-at 導入の経緯を参照）。実際には入力待ちなのに一覧の
-- 下に沈むと「待機中の Agent を探す」用途で取りこぼすため、最終更新時刻からの経過で
-- 判定して繰り上げる。長い思考で誤って繰り上げても実害は無い（順番と印が変わるだけ）。
M.STALE_SECONDS = 300

-- @agent-status が空でも、ペインで直接起動している Agent は拾いたいので
-- pane_current_command でも判定する。
M.AGENT_COMMANDS = {
  claude = true,
  codex = true,
  pi = true,
}
local AGENT_COMMANDS = M.AGENT_COMMANDS

local FIELDS = table.concat({
  "#{pane_id}",
  "#{@agent-status}",
  "#{@agent-status-at}",
  "#{@pane-task}",
  "#{pane_current_path}",
  "#{session_name}",
  "#{window_index}",
  "#{pane_index}",
  "#{@nvim-server}",
  "#{pane_current_command}",
}, "\t")

-- auto-rename.sh と同じ規則でプロジェクト名を取り出す。
-- $HOME/src/github.com/<owner>/<repo>/... -> <repo>
-- それ以外 -> ディレクトリのベース名
function M.project_name(path)
  if not path or path == "" then
    return ""
  end

  local home = vim.env.HOME or ""
  local rest = path
  if home ~= "" and vim.startswith(path, home) then
    rest = path:sub(#home + 1)
  end

  local under_github = rest:match("^/src/github%.com/(.+)$")
  if under_github then
    local parts = vim.split(under_github, "/", { plain = true })
    -- worktree は <repo>-wt/<slug> に置く運用なので、slug のほうを出す。
    -- 親リポジトリ名だけだとどの worktree か分からないため。
    if #parts > 2 and parts[2]:match("%-wt$") then
      return parts[3]
    end
    if #parts > 1 then
      return parts[2]
    end
    return parts[1]
  end

  if path == home then
    return "~"
  end
  return vim.fs.basename(path) or ""
end

local function parse_line(line, now)
  local f = vim.split(line, "\t", { plain = true })
  if #f < 10 then
    return nil
  end

  local status = f[2]
  local status_at = tonumber(f[3]) or 0
  -- 時刻が無いペイン（この機能より前に状態を書かれた場合）は判定できないので
  -- stale にしない。誤って繰り上げるより、そのままにしておくほうが素直。
  local stale = status == "running" and status_at > 0 and (now - status_at) > M.STALE_SECONDS

  return {
    pane_id = f[1],
    status = status,
    status_at = status_at,
    stale = stale,
    task = f[4],
    path = f[5],
    session = f[6],
    window_index = tonumber(f[7]) or 0,
    pane_index = tonumber(f[8]) or 0,
    nvim_server = f[9],
    command = f[10],
    project = M.project_name(f[5]),
  }
end

local function is_agent_pane(p)
  return p.status ~= "" or AGENT_COMMANDS[p.command] == true
end

local function rank(p)
  if p.stale then
    return STALE_RANK
  end
  return STATUS_RANK[p.status] or UNKNOWN_RANK
end

-- Agent が乗っているペインを、状態で大分類し、同分類内は画面上の位置順で返す。
-- 自分のペインは含めない（ローカル宛は <M-a> が担当するため）。
function M.list()
  if not vim.env.TMUX then
    return {}
  end

  local out = vim.fn.systemlist({ "tmux", "list-panes", "-a", "-F", FIELDS })
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local self_pane = vim.env.TMUX_PANE
  local now = os.time()
  local panes = {}
  for _, line in ipairs(out) do
    local p = parse_line(line, now)
    if p and p.pane_id ~= self_pane and is_agent_pane(p) then
      table.insert(panes, p)
    end
  end

  table.sort(panes, function(a, b)
    local ra, rb = rank(a), rank(b)
    if ra ~= rb then
      return ra < rb
    end
    if a.session ~= b.session then
      return a.session < b.session
    end
    if a.window_index ~= b.window_index then
      return a.window_index < b.window_index
    end
    return a.pane_index < b.pane_index
  end)

  return panes
end

-- ペインがまだ存在するか。送信直前の検証に使う。
function M.exists(pane_id)
  if not pane_id or pane_id == "" then
    return false
  end
  -- tmux display-message は存在しないペインでも終了コード 0 を返し、出力だけが
  -- 空になる。終了コードでは判定できないので、返ってきた pane_id を突き合わせる。
  local out = vim.fn.system({ "tmux", "display-message", "-p", "-t", pane_id, "#{pane_id}" })
  if vim.v.shell_error ~= 0 then
    return false
  end
  return vim.trim(out) == pane_id
end

return M
