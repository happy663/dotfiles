-- herdr 向けの送り先（agent_term/outer/status.lua の sink）。issue #351。
-- herdr 0.9.5 は OSC 7501 を理解しないので、報告を herdr の CLI 呼び出しに変換する。
--   herdr pane report-agent  <pane> --source <src> --agent <label> --state <state> [--message <msg>] --seq <n>
--   herdr pane release-agent <pane> --source <src> --agent <label> --seq <n>
-- herdr が OSC 7501 に対応したら（herdrdev/herdr#5172）、rex.lua と同じく転送だけにできる。
--
-- herdr はペインごとに 1 つの状態しか持たない。1 つの Neovim で動かすエージェントはほぼ 1 つなので、
-- 最後に報告したバッファの状態をそのまま出す。

local M = {}

-- herdr 公式の連携用の source（herdr:claude など）は予約されていて状態が反映されないため、独自の名前を使う
M.SOURCE = "dotfiles:agent-term"

-- OSC 7501 の状態 → { herdr の状態, メッセージ }。herdr が受け付けるのは working / blocked / idle だけ。
-- done は idle として送る（そのペインを見ていなければ、herdr が自分で done と表示する）。
-- error は herdr に対応する状態がないので、idle にメッセージを付ける。
local STATES = {
  working = { "working" },
  blocked = { "blocked" },
  idle = { "idle" },
  done = { "idle" },
  error = { "idle", "error" },
}

-- OSC 7501 の app → herdr のエージェント名（herdr のサイドバーの表示や設定のキーに使われる）
local AGENTS = {
  ["claude-code"] = "claude",
}

-- herdr の中か（herdr は各ペインに HERDR_ENV=1 と HERDR_PANE_ID を入れる）
function M.available()
  return vim.env.HERDR_ENV == "1" and vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= ""
end

local function default_run(argv)
  vim.system(argv, { text = true }, function() end)
end

-- herdr は source ごとに seq が増えた報告だけを新しいものとして扱う。
-- 非同期に呼ぶので届く順が入れ替わることがあり、Neovim を開き直しても前より大きくなるよう、
-- 起動からの経過時間（マイクロ秒、マシン全体で単調増加）を使う。
local function default_seq()
  return math.floor(vim.uv.hrtime() / 1000)
end

-- opts.bin:     herdr のコマンド（既定: "herdr"）
-- opts.pane_id: 報告先のペイン（既定: HERDR_PANE_ID）
-- opts.run:     argv を実行する関数（既定: vim.system で非同期）。テスト用
-- opts.seq:     seq を返す関数。テスト用
function M.new(opts)
  opts = opts or {}
  local bin = opts.bin or "herdr"
  local pane = opts.pane_id or vim.env.HERDR_PANE_ID
  local run = opts.run or default_run
  local seq = opts.seq or default_seq

  -- 最後に送った内容 { bufnr, agent, state, message }
  local current = nil

  local function call(argv)
    pcall(run, argv)
  end

  local function release()
    if not current then
      return
    end
    call({
      bin,
      "pane",
      "release-agent",
      pane,
      "--source",
      M.SOURCE,
      "--agent",
      current.agent,
      "--seq",
      tostring(seq()),
    })
    current = nil
  end

  local function report(bufnr, pairs)
    local kv = {}
    for _, pair in ipairs(pairs) do
      if kv[pair[1]] == nil then
        kv[pair[1]] = pair[2]
      end
    end
    -- id 付きは子の記録（サブエージェントなど）。herdr はペインに 1 つしか持てないので、本体だけを送る
    if kv.id then
      return
    end
    if kv.state == "clear" then
      if current and current.bufnr == bufnr then
        release()
      end
      return
    end
    local mapped = STATES[kv.state]
    if not mapped then
      return
    end

    local agent = AGENTS[kv.app] or kv.app or "agent"
    local state, message = mapped[1], mapped[2]
    if current then
      if
        current.bufnr == bufnr
        and current.agent == agent
        and current.state == state
        and current.message == message
      then
        return
      end
      if current.bufnr ~= bufnr or current.agent ~= agent then
        release()
      end
    end

    local argv = { bin, "pane", "report-agent", pane, "--source", M.SOURCE, "--agent", agent, "--state", state }
    if message then
      vim.list_extend(argv, { "--message", message })
    end
    vim.list_extend(argv, { "--seq", tostring(seq()) })
    call(argv)
    current = { bufnr = bufnr, agent = agent, state = state, message = message }
  end

  return {
    report = report,
    clear = function(bufnr)
      if current and current.bufnr == bufnr then
        release()
      end
    end,
  }
end

return M
