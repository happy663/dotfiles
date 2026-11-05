package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local config = require("agent_term.config")
local draft_buf = require("agent_term.draft_buf")
local state = require("agent_term.local.state")
local terminals = require("agent_term.local.terminals")
local draft = require("agent_term.local.draft")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function assert_true(value, message)
  if not value then
    error(message .. ": expected truthy, got " .. tostring(value))
  end
end

local function is_float(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ""
end

-- 疑似ターミナル（プロセス無しの terminal バッファ）だけを表示したタブを作る
local function make_term_tab()
  vim.cmd("tabnew")
  local term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_term(term_buf, {})
  vim.api.nvim_win_set_buf(0, term_buf)
  state.set_target_terminal_bufnr(term_buf)
  return term_buf, vim.api.nvim_get_current_win()
end

draft.setup()

-- 1. float_win_config: ターミナルの下端から bottom_margin 行上に、ターミナル幅で置く
do
  local cfg = draft_buf.float_win_config({ row = 1, col = 4, width = 80, height = 30 }, 8, { bottom_margin = 3 })
  assert_eq(cfg.relative, "editor", "float relative")
  assert_eq(cfg.border, "rounded", "float border")
  -- 枠線が左右で2列使うため、外寸がターミナル幅に一致するよう内寸は width - 2
  assert_eq(cfg.width, 78, "float width")
  assert_eq(cfg.height, 8, "float height")
  -- row = 1 + 30 - 8 - 2(枠線) - 3(margin) = 18
  assert_eq(cfg.row, 18, "float row")
  assert_eq(cfg.col, 4, "float col")
end

-- 2. float_win_config: ターミナルが小さいときは高さを縮め、上端より上には出さない
do
  local cfg = draft_buf.float_win_config({ row = 2, col = 0, width = 40, height = 10 }, 8, { bottom_margin = 3 })
  -- 使える高さ = 10 - 2(枠線) - 3(margin) = 5
  assert_eq(cfg.height, 5, "clamped float height")
  assert_eq(cfg.row, 2, "clamped float row")

  local tiny = draft_buf.float_win_config({ row = 0, col = 0, width = 2, height = 3 }, 8, { bottom_margin = 3 })
  assert_true(tiny.height >= 1, "tiny float height is at least 1")
  assert_true(tiny.width >= 1, "tiny float width is at least 1")
  assert_true(tiny.row >= 0, "tiny float row is not negative")
end

-- 3. style = "float": focus_or_open はフロートで開き、ターミナルの高さを変えない
do
  config.draft.style = "float"
  local term_buf, term_win = make_term_tab()
  local before_height = vim.api.nvim_win_get_height(term_win)

  local ok = draft.focus_or_open({ target_bufnr = term_buf, draft_height = 8 })
  assert_true(ok, "focus_or_open (float) succeeds")

  local float_win = vim.api.nvim_get_current_win()
  assert_true(is_float(float_win), "draft window is floating")
  assert_eq(vim.api.nvim_win_get_buf(float_win), state.get_draft_bufnr(), "float shows draft buffer")
  assert_eq(vim.b[state.get_draft_bufnr()].agent_input, true, "draft buffer is marked agent_input")
  assert_eq(vim.api.nvim_win_get_height(term_win), before_height, "terminal height unchanged after open")
  assert_eq(vim.api.nvim_win_get_width(float_win), vim.api.nvim_win_get_width(term_win) - 2, "float fits terminal")

  -- hide でフロートが閉じ、ターミナルの高さはそのまま
  local hidden = draft.hide()
  assert_true(hidden, "hide succeeds")
  assert_eq(vim.api.nvim_win_is_valid(float_win), false, "float closed after hide")
  assert_eq(vim.api.nvim_win_get_height(term_win), before_height, "terminal height unchanged after hide")

  -- 既存の下書きを開き直してもフロートになり、同じバッファを使う
  local draft_bufnr = state.get_draft_bufnr()
  vim.api.nvim_set_current_win(term_win)
  assert_true(draft.focus_or_open({ draft_height = 8 }), "reopen succeeds")
  local reopened = vim.api.nvim_get_current_win()
  assert_true(is_float(reopened), "reopened draft is floating")
  assert_eq(vim.api.nvim_win_get_buf(reopened), draft_bufnr, "reopened float reuses draft buffer")

  -- ターミナルの幅が変わったら位置を合わせ直す
  vim.api.nvim_set_current_win(term_win)
  vim.cmd("leftabove vnew")
  draft.reposition_floats()
  assert_eq(
    vim.api.nvim_win_get_width(reopened),
    vim.api.nvim_win_get_width(term_win) - 2,
    "float follows terminal width after resize"
  )
end

-- 3b. float.winblend: フロートに winblend を設定し、後ろのターミナルの文字を透かす
do
  config.draft.style = "float"
  local orig_float = config.draft.float
  config.draft.float = vim.tbl_extend("force", orig_float, { winblend = 25 })

  local term_buf = make_term_tab()
  assert_true(draft.focus_or_open({ target_bufnr = term_buf, draft_height = 8 }), "open float with winblend")
  local float_win = vim.api.nvim_get_current_win()
  assert_eq(vim.wo[float_win].winblend, 25, "float winblend from config")

  -- winblend は空白セルを透かすため、本文中の空白・タブは見た目が空白の NBSP で描いて
  -- 透けるのを行末より後ろだけにする（表示だけで、バッファの中身は変えない）
  local nbsp = "\u{00a0}"
  assert_eq(vim.wo[float_win].list, true, "float list enabled for NBSP spaces")
  local listchars = vim.opt_local.listchars:get()
  assert_eq(listchars.space, nbsp, "space drawn as NBSP")
  assert_eq(listchars.tab, nbsp .. nbsp, "tab drawn as NBSP")
  assert_eq(listchars.eol, nil, "no eol marker")

  config.draft.float = orig_float
end

-- 3c. OptionSet: cmdheight など画面の行の並びを変えるオプションが変わったら、
--     WinResized が来なくてもフロートを合わせ直す
--     （起動途中に noice が cmdheight を 0 にしたとき WinResized が発火せず、1 行ずれた）
do
  config.draft.style = "float"
  local term_buf, term_win = make_term_tab()
  assert_true(draft.focus_or_open({ target_bufnr = term_buf, draft_height = 8 }), "open float for OptionSet")
  local float_win = vim.api.nvim_get_current_win()

  local function bottom_aligned()
    local cfg = vim.api.nvim_win_get_config(float_win)
    local term_bottom = vim.api.nvim_win_get_position(term_win)[1] + vim.api.nvim_win_get_height(term_win)
    -- 枠線の下端（row + height + 2）がターミナルの下端と一致する
    return cfg.row + cfg.height + 2 == term_bottom
  end
  assert_true(bottom_aligned(), "float aligned before cmdheight change")

  -- headless では cmdheight を変えてもウィンドウの高さが再計算されないため、
  -- ターミナルの高さは split で変える。WinResized / VimResized は止めておき、
  -- OptionSet（実機で cmdheight が変わったときに確実に発火していたイベント）だけで追従するかを見る。
  local orig_ei = vim.go.eventignore
  vim.go.eventignore = "WinResized,VimResized"
  vim.api.nvim_set_current_win(term_win)
  vim.cmd("belowright 3split")
  local extra_win = vim.api.nvim_get_current_win()
  assert_eq(bottom_aligned(), false, "terminal height changed under the float")
  -- headless の -l 実行では OptionSet が自然に発火しない場合があるため、明示的にも発火させる
  vim.api.nvim_exec_autocmds("OptionSet", { pattern = "cmdheight", group = "AgentInputFloatReposition" })
  vim.go.eventignore = orig_ei
  assert_true(bottom_aligned(), "float follows terminal on OptionSet without WinResized")

  vim.api.nvim_win_close(extra_win, true)
  draft.reposition_floats()
end

-- 4. style = "split": 従来どおり split で開く
do
  config.draft.style = "split"
  local term_buf, term_win = make_term_tab()
  local before_height = vim.api.nvim_win_get_height(term_win)

  assert_true(draft.focus_or_open({ target_bufnr = term_buf, draft_height = 8 }), "focus_or_open (split) succeeds")
  local win = vim.api.nvim_get_current_win()
  assert_eq(is_float(win), false, "draft window is a split")
  assert_true(vim.api.nvim_win_get_height(term_win) < before_height, "terminal shrinks with split draft")
end

-- 5. send_draft: フロートなら送信前のリサイズ待ち (vim.wait) をしない。split なら従来どおり待つ
do
  local orig_wait = vim.wait
  local orig_send = terminals.send_command

  local function send_with_style(style)
    config.draft.style = style
    local term_buf = make_term_tab()
    assert_true(draft.focus_or_open({ target_bufnr = term_buf, draft_height = 8 }), "open for send (" .. style .. ")")
    local draft_win = vim.api.nvim_get_current_win()
    vim.api.nvim_buf_set_lines(state.get_draft_bufnr(), 0, -1, false, { "hello", "" })

    local waited = false
    local sent = {}
    vim.wait = function(...)
      waited = true
      return true
    end
    terminals.send_command = function(_, text)
      table.insert(sent, text)
      return true, "sent"
    end

    local ok = draft.send_draft({ clear_input = false })

    vim.wait = orig_wait
    terminals.send_command = orig_send

    assert_true(ok, "send_draft succeeds (" .. style .. ")")
    assert_eq(sent[1], "hello", "sent content (" .. style .. ")")
    assert_eq(vim.api.nvim_win_is_valid(draft_win), false, "draft hidden after send (" .. style .. ")")
    return waited
  end

  assert_eq(send_with_style("float"), false, "float send does not wait for resize")
  assert_eq(send_with_style("split"), true, "split send waits for resize")
end

-- 6. layouts: Agent タブを作った直後の下書きも style に従う
do
  local layouts = require("agent_term.layouts")

  local function normal_wins()
    local wins = {}
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if not is_float(winid) then
        table.insert(wins, winid)
      end
    end
    return wins
  end

  -- float: ターミナルは分割されず、下書きはそのターミナルに重なるフロート
  config.draft.style = "float"
  layouts.open_agent_claude({ command = "cat" })
  local wins = normal_wins()
  assert_eq(#wins, 1, "claude layout (float) has only the terminal window")
  local current = vim.api.nvim_get_current_win()
  assert_true(is_float(current), "claude layout (float) focuses draft float")
  assert_eq(vim.api.nvim_win_get_buf(current), state.get_draft_bufnr(), "claude layout float shows draft")
  assert_eq(vim.api.nvim_win_get_width(current), vim.api.nvim_win_get_width(wins[1]) - 2, "draft fits claude terminal")

  -- float: claude_codex では左の claude ウィンドウに重なる
  layouts.open_agent_claude_codex({ claude_command = "cat", codex_command = "cat" })
  wins = normal_wins()
  assert_eq(#wins, 2, "claude_codex layout (float) has only two terminals")
  local claude_win
  for _, winid in ipairs(wins) do
    if vim.api.nvim_win_get_buf(winid) == state.get_target_terminal_bufnr() then
      claude_win = winid
    end
  end
  assert_true(claude_win, "claude terminal window found")
  current = vim.api.nvim_get_current_win()
  assert_true(is_float(current), "claude_codex layout (float) focuses draft float")
  assert_eq(
    vim.api.nvim_win_get_position(current)[2],
    vim.api.nvim_win_get_position(claude_win)[2],
    "draft over claude"
  )
  assert_eq(vim.api.nvim_win_get_width(current), vim.api.nvim_win_get_width(claude_win) - 2, "draft fits claude width")

  -- float: ターミナルから AgentDraft 相当 (open_term_draft) で開く
  local term_buf = make_term_tab()
  layouts.open_term_draft({ draft_height = 8 })
  assert_eq(#normal_wins(), 1, "open_term_draft (float) does not split")
  assert_true(is_float(vim.api.nvim_get_current_win()), "open_term_draft (float) opens float")
  assert_eq(state.get_target_terminal_bufnr(), term_buf, "open_term_draft keeps target terminal")

  -- split: 従来どおりターミナルの下に split で開く
  config.draft.style = "split"
  layouts.open_agent_claude({ command = "cat" })
  assert_eq(#normal_wins(), 2, "claude layout (split) splits terminal and draft")
  assert_eq(is_float(vim.api.nvim_get_current_win()), false, "claude layout (split) draft is a split")
  config.draft.style = "float"
end

-- 7. no-neck-pain: 起動直後（enableOnVimEnter が未消化 = state == nil）なら、
--    フロートを開く前に通常ウィンドウ上で有効化する（フロート上だと nnp が有効化をスキップするため）
do
  config.draft.style = "float"
  local enable_calls = {}
  package.loaded["no-neck-pain.main"] = {
    enable = function(scope)
      table.insert(enable_calls, { scope = scope, on_float = is_float(vim.api.nvim_get_current_win()) })
      _G.NoNeckPain.state = { enabled = true }
    end,
  }

  -- 未有効化（起動直後）: フロートを開く前に通常ウィンドウ上で enable が呼ばれる
  _G.NoNeckPain = { config = { autocmds = { enableOnVimEnter = "safe" } }, state = nil }
  local term_buf = make_term_tab()
  draft.open_for_target({ target_bufnr = term_buf, draft_height = 8 })
  assert_eq(#enable_calls, 1, "nnp enabled before opening float at startup")
  assert_eq(enable_calls[1].on_float, false, "nnp enabled while a normal window is focused")
  assert_true(is_float(vim.api.nvim_get_current_win()), "draft float still focused after nnp enable")

  -- 一度有効化済み / ユーザーが無効化済み（state あり）: 何もしない
  _G.NoNeckPain.state = { enabled = false }
  term_buf = make_term_tab()
  draft.open_for_target({ target_bufnr = term_buf, draft_height = 8 })
  assert_eq(#enable_calls, 1, "nnp not enabled when state already exists")

  -- enableOnVimEnter を使っていない: 何もしない
  _G.NoNeckPain = { config = { autocmds = { enableOnVimEnter = false } }, state = nil }
  term_buf = make_term_tab()
  draft.open_for_target({ target_bufnr = term_buf, draft_height = 8 })
  assert_eq(#enable_calls, 1, "nnp not enabled when enableOnVimEnter is off")

  -- split: 通常ウィンドウにフォーカスが残るので nnp 自身に任せる
  config.draft.style = "split"
  _G.NoNeckPain = { config = { autocmds = { enableOnVimEnter = "safe" } }, state = nil }
  term_buf = make_term_tab()
  draft.open_for_target({ target_bufnr = term_buf, draft_height = 8 })
  assert_eq(#enable_calls, 1, "nnp not touched in split style")

  config.draft.style = "float"
  _G.NoNeckPain = nil
  package.loaded["no-neck-pain.main"] = nil
end

print("agent_term draft float tests passed")
