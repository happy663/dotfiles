-- クラウドの Claude Code セッションを、入力バッファ経由で作って接続する。
--
-- シェルで `claude --cloud "<説明>"` を直接打つ形だと、シェル側で日本語入力を無効に
-- している環境では説明を書けない。入力を nvim のバッファへ寄せることで、シェルに
-- 日本語を打たずにクラウドセッションを開始できる。
--
-- `claude --cloud` の説明はタイトルと初回プロンプトの両方になる（1行目がタイトル、
-- 本文全体がプロンプト）。接続後は通常の Claude レイアウトへ引き継ぐため、以降の
-- やり取りは既存の draft バッファ（<M-a> / <C-CR>）でそのまま行える。
--
-- 注意1: `claude --cloud` は TTY を要求し、パイプ経由で呼ぶと
--   "--cloud requires an interactive terminal."
-- で拒否される。そのため vim.system ではなく pty つきの jobstart を使う。
--
-- 注意2: `claude --teleport` はローカルの git ブランチを切り替える。未コミット変更が
-- あると stash を促されるため、必ず専用の worktree を切ってそこで teleport する。
-- worktree の命名は AGENTS.md / git-worktree スキルに合わせて branch `wt/<slug>`、
-- path `../<repo>-wt/<slug>`。slug は日本語本文から機械的に作れないので、ユーザーに
-- 英語で指定してもらう。
local draft_buf = require("agent_term.draft_buf")
local layouts = require("agent_term.layouts")

local M = {}

local INPUT_BUF_NAME = "[Agent Cloud Input]"
-- pty の幅。狭いと出力が折り返され、session id が行をまたいで分断される。
local PTY_WIDTH = 300
local SESSION_PATTERN = "session_%w+"
local SLUG_PATTERN = "^%w[%w%-_.]*$"

local input_bufnr = nil
local input_tabpage = nil
local pending_slug = nil
local running = false

local function notify(message, level)
  vim.notify("[AgentClaudeCloud] " .. message, level or vim.log.levels.INFO)
end

-- pty 出力から制御シーケンスを落とす。診断表示用。
local function strip_ansi(text)
  return (text:gsub("\27%[[%d;?]*[%a]", ""):gsub("\27%][^\7]*\7", ""):gsub("\r", ""))
end

local function git(args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  local stdout = (res.stdout or ""):gsub("%s+$", "")
  local stderr = (res.stderr or ""):gsub("%s+$", "")
  return res.code == 0, stdout, stderr
end

local function ensure_input_buffer()
  if input_bufnr and vim.api.nvim_buf_is_valid(input_bufnr) then
    return input_bufnr
  end

  input_bufnr = draft_buf.create_input_buffer(INPUT_BUF_NAME)
  draft_buf.apply_send_keymaps(input_bufnr, {
    send = "AgentClaudeCloudCreate",
    clear = "AgentClaudeCloudClear",
  })
  return input_bufnr
end

local function close_input_tab()
  local tabpage = input_tabpage
  input_tabpage = nil

  if not (tabpage and vim.api.nvim_tabpage_is_valid(tabpage)) then
    return
  end
  -- 最後の1枚は閉じられない。teleport 用タブを作った後に呼ぶ前提。
  if #vim.api.nvim_list_tabpages() <= 1 then
    return
  end

  pcall(vim.cmd, vim.api.nvim_tabpage_get_number(tabpage) .. "tabclose")
end

-- 入力バッファのみを新規タブに開く。ターミナルはこの時点では作らない。
-- slug は worktree 名。省略した場合は送信時に尋ねる。
function M.open(slug)
  if slug and slug ~= "" then
    pending_slug = slug
  end

  local bufnr = ensure_input_buffer()

  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("startinsert")
      return bufnr
    end
  end

  vim.cmd("tabnew")
  input_tabpage = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.cmd("startinsert")
  return bufnr
end

-- 既にリンクされた worktree の中にいるかどうか。
-- main worktree では --git-dir と --git-common-dir が一致する。
local function inside_linked_worktree()
  local ok1, git_dir = git({ "rev-parse", "--absolute-git-dir" })
  local ok2, common_dir = git({ "rev-parse", "--path-format=absolute", "--git-common-dir" })
  if not (ok1 and ok2) then
    return false
  end
  return git_dir ~= common_dir
end

-- slug から worktree の branch / path を決める。衝突していれば理由を返す。
local function plan_worktree(slug)
  if not slug:match(SLUG_PATTERN) then
    return nil, ("worktree 名が不正です: %s（英数字で始まり、英数字 - _ . のみ）"):format(slug)
  end

  local ok, root = git({ "rev-parse", "--show-toplevel" })
  if not ok or root == "" then
    return nil, "git リポジトリではありません"
  end

  local branch = "wt/" .. slug
  local path = ("%s/%s-wt/%s"):format(vim.fn.fnamemodify(root, ":h"), vim.fn.fnamemodify(root, ":t"), slug)

  if git({ "show-ref", "--verify", "--quiet", "refs/heads/" .. branch }) then
    return nil, "branch が既に存在します: " .. branch
  end
  if vim.uv.fs_stat(path) then
    return nil, "path が既に存在します: " .. path
  end

  local base_ok, base = git({ "branch", "--show-current" })
  if not base_ok or base == "" then
    return nil, "現在の branch を取得できません（detached HEAD の可能性）"
  end

  return { branch = branch, path = path, base = base }
end

local function create_worktree(plan)
  vim.fn.mkdir(vim.fn.fnamemodify(plan.path, ":h"), "p")
  local ok, _, stderr = git({ "worktree", "add", "-b", plan.branch, plan.path, plan.base })
  if not ok then
    return false, "worktree の作成に失敗しました: " .. stderr
  end
  return true
end

-- worktree の中で teleport する。layouts が cwd を取らないため cd を挟む。
local function attach(session_id, cwd)
  local command = ("cd %s && claude --teleport %s"):format(vim.fn.shellescape(cwd), session_id)
  layouts.open_agent_claude({ command = command, open_draft = true })
  close_input_tab()
  notify(("接続しました: %s\n%s"):format(session_id, cwd))
end

local function run_create(content, plan)
  local output = {}
  running = true
  notify("cloud session を作成中...")

  -- cwd を明示するのは、信頼していないディレクトリだと claude が確認プロンプトを
  -- 出して pty 上で応答待ちのまま止まるため。
  local job_id = vim.fn.jobstart({ "claude", "--cloud", content }, {
    pty = true,
    width = PTY_WIDTH,
    cwd = vim.fn.getcwd(),
    on_stdout = function(_, data)
      if data then
        vim.list_extend(output, data)
      end
    end,
    on_exit = function(_, code)
      running = false

      local text = table.concat(output, "\n")
      local session_id = text:match(SESSION_PATTERN)
      -- 失敗しても入力バッファは残す（書いた本文を失わないため）。
      if code ~= 0 or not session_id then
        local detail = strip_ansi(text):gsub("%s+$", ""):sub(-400)
        notify(("セッション作成に失敗しました (exit=%d)\n%s"):format(code, detail), vim.log.levels.ERROR)
        return
      end

      local cwd = vim.fn.getcwd()
      if plan then
        local ok, err = create_worktree(plan)
        -- worktree を作れなければ teleport しない。元の作業ツリーで
        -- ブランチを切り替えられる方が危険なため、session id だけ伝える。
        if not ok then
          notify(
            ("%s\n作成済みセッション: claude --teleport %s"):format(err, session_id),
            vim.log.levels.ERROR
          )
          return
        end
        cwd = plan.path
      end

      draft_buf.clear(input_bufnr)
      pending_slug = nil
      attach(session_id, cwd)
    end,
  })

  if job_id <= 0 then
    running = false
    notify("claude の起動に失敗しました", vim.log.levels.ERROR)
  end
end

-- 入力バッファの内容でクラウドセッションを作り、worktree を切って teleport する。
function M.create()
  if running then
    notify("作成中です", vim.log.levels.WARN)
    return
  end
  if not (input_bufnr and vim.api.nvim_buf_is_valid(input_bufnr)) then
    notify("入力バッファがありません。:AgentClaudeCloud で開いてください", vim.log.levels.ERROR)
    return
  end

  local content = draft_buf.read_content(input_bufnr)
  if content == "" then
    notify("本文が空です", vim.log.levels.WARN)
    return
  end

  -- 既に worktree の中なら、そこで teleport する（worktree を増やさない）。
  if inside_linked_worktree() then
    run_create(content, nil)
    return
  end

  local function with_slug(slug)
    if not slug or slug == "" then
      notify("worktree 名が未指定のため中止しました", vim.log.levels.WARN)
      return
    end

    local plan, err = plan_worktree(slug)
    if not plan then
      notify(err, vim.log.levels.ERROR)
      return
    end
    run_create(content, plan)
  end

  if pending_slug then
    with_slug(pending_slug)
    return
  end

  vim.ui.input({ prompt = "worktree 名 (英語): " }, with_slug)
end

function M.clear()
  if not (input_bufnr and vim.api.nvim_buf_is_valid(input_bufnr)) then
    notify("入力バッファがありません", vim.log.levels.WARN)
    return
  end
  draft_buf.clear(input_bufnr)
  notify("入力バッファをクリアしました")
end

return M
