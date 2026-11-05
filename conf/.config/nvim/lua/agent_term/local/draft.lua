local config = require("agent_term.config")
local draft_buf = require("agent_term.draft_buf")
local state = require("agent_term.local.state")
local terminals = require("agent_term.local.terminals")

local M = {}
M.fallback_target_patterns = config.draft.fallback_target_patterns

local tab_bufnr_registry = {}
local setup_done = false

local function notify(msg, level)
  vim.notify("[agent_input] " .. msg, level or vim.log.levels.INFO)
end

local function resize_current_draft_window(default_height)
  local height = state.get_draft_height(default_height)
  if height then
    vim.cmd("resize " .. tostring(height))
  end
end

local function save_visible_draft_height(bufnr)
  if not state.is_valid_buf(bufnr) then
    return
  end

  local current_tabpage = vim.api.nvim_get_current_tabpage()
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if
      vim.api.nvim_win_is_valid(winid)
      and vim.api.nvim_win_get_tabpage(winid) == current_tabpage
      and vim.api.nvim_win_get_buf(winid) == bufnr
    then
      state.set_draft_height(vim.api.nvim_win_get_height(winid))
      return
    end
  end
end

local function focus_existing_draft(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("startinsert")
      return true
    end
  end
  return false
end

local function resolve_target_terminal_bufnr(fallback_target_patterns)
  local target_bufnr = state.get_target_terminal_bufnr()
  if state.is_valid_buf(target_bufnr) then
    return target_bufnr
  end

  local terminal = terminals.find_terminal_by_pattern(fallback_target_patterns, false)
  if terminal and state.is_valid_buf(terminal.bufnr) then
    return terminal.bufnr
  end

  return nil
end

local function resolve_target_terminal_winid(target_bufnr, fallback_target_patterns)
  local current_tab_wins = vim.api.nvim_tabpage_list_wins(0)

  local function find_winid_for(bufnr)
    if not state.is_valid_buf(bufnr) then
      return nil
    end
    for _, winid in ipairs(current_tab_wins) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
        return winid
      end
    end
    return nil
  end

  local winid = find_winid_for(target_bufnr)
  if winid then
    return winid
  end

  local terminal = terminals.find_terminal_by_pattern(fallback_target_patterns, false)
  if terminal and state.is_valid_buf(terminal.bufnr) then
    return find_winid_for(terminal.bufnr)
  end

  return nil
end

local function open_split_below_target(target_bufnr, fallback_target_patterns, draft_height)
  local target_winid = resolve_target_terminal_winid(target_bufnr, fallback_target_patterns)
  if target_winid then
    vim.api.nvim_set_current_win(target_winid)
    vim.cmd("belowright split")
    resize_current_draft_window(draft_height)

    local draft_winid = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(target_winid) then
      local term_bufnr = vim.api.nvim_win_get_buf(target_winid)
      if state.is_valid_buf(term_bufnr) then
        local line_count = vim.api.nvim_buf_line_count(term_bufnr)
        pcall(vim.api.nvim_win_set_cursor, target_winid, { line_count, 0 })
      end
    end
    if vim.api.nvim_win_is_valid(draft_winid) then
      vim.api.nvim_set_current_win(draft_winid)
    end

    return true
  end

  vim.cmd("botright split")
  resize_current_draft_window(draft_height)
  return false
end

local function use_float()
  return config.draft.style == "float"
end

local function is_float_win(winid)
  return vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_config(winid).relative ~= ""
end

-- 下書きが split（フロートでない通常ウィンドウ）で表示されているか。
-- split を閉じるとターミナルの高さが変わるので、送信前に再描画を待つ必要がある。
local function has_split_window(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) and not is_float_win(winid) then
      return true
    end
  end
  return false
end

-- フロートを重ねる先の画面上の位置と大きさ。
-- ターミナルウィンドウが無ければエディタ全体（タブライン・コマンドラインを除く）を使う。
local function float_anchor(target_winid)
  if target_winid and vim.api.nvim_win_is_valid(target_winid) then
    local pos = vim.api.nvim_win_get_position(target_winid)
    return {
      row = pos[1],
      col = pos[2],
      width = vim.api.nvim_win_get_width(target_winid),
      height = vim.api.nvim_win_get_height(target_winid),
    }
  end

  local showtabline = vim.o.showtabline
  local tabline = (showtabline == 2 or (showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)) and 1 or 0
  return {
    row = tabline,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - vim.o.cmdheight - tabline - 1,
  }
end

local function float_config_for(target_winid, height)
  return draft_buf.float_win_config(float_anchor(target_winid), height, {
    bottom_margin = config.draft.float and config.draft.float.bottom_margin or 0,
    title = " Agent Input ",
  })
end

-- 下書きをターミナルの下端に重ねたフロートで開く。ターミナルが見つかれば true。
local function open_float(bufnr, target_bufnr, fallback_target_patterns, default_height)
  local target_winid = resolve_target_terminal_winid(target_bufnr, fallback_target_patterns)
  local height = state.get_draft_height(default_height) or config.draft.attached_height
  local winid = vim.api.nvim_open_win(bufnr, true, float_config_for(target_winid, height))
  -- 後ろのターミナル（Agent の出力）を空白セル越しに透かして見せる
  local winblend = config.draft.float and config.draft.float.winblend
  if type(winblend) == "number" and winblend > 0 then
    vim.wo[winid].winblend = winblend
    -- winblend は空白セルをすべて透かすため、そのままだと本文の単語間やインデントにも
    -- 後ろの文字が入り込む。空白・タブを見た目が空白の NBSP で描き、透けるのを
    -- 行末より後ろだけにする（表示だけで、バッファの中身は変えない）。
    local nbsp = "\u{00a0}"
    local local_win = { scope = "local", win = winid }
    vim.api.nvim_set_option_value("list", true, local_win)
    vim.api.nvim_set_option_value(
      "listchars",
      string.format("space:%s,tab:%s%s,nbsp:%s", nbsp, nbsp, nbsp, nbsp),
      local_win
    )
  end
  -- 位置の合わせ直し (reposition_floats) で使う
  vim.w[winid].agent_input_float = true
  vim.w[winid].agent_input_anchor_win = target_winid
  vim.w[winid].agent_input_float_height = height
  return target_winid ~= nil
end

-- ターミナルの大きさが変わったとき、下書きフロートの位置と幅を合わせ直す。
function M.reposition_floats()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) and vim.w[winid].agent_input_float then
      local cfg = float_config_for(vim.w[winid].agent_input_anchor_win, vim.w[winid].agent_input_float_height)
      pcall(vim.api.nvim_win_set_config, winid, cfg)
    end
  end
end

local function ensure_buffer_keymaps(bufnr)
  draft_buf.apply_send_keymaps(bufnr, {
    send = "AgentDraftSend",
    send_keep = "AgentDraftSend!",
    clear = "AgentDraftClear",
  })
  vim.keymap.set("n", "<C-p>", function()
    require("telescope").load_extension("smart_open")
    require("telescope").extensions.smart_open.smart_open({
      attach_mappings = function(prompt_bufnr, _)
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi = picker:get_multi_selection()
          actions.close(prompt_bufnr)

          local paths = {}
          if #multi > 0 then
            for _, entry in ipairs(multi) do
              local fp = entry.path or entry.filename
              if fp then
                table.insert(paths, "@" .. vim.fn.fnamemodify(fp, ":."))
              end
            end
          else
            local entry = action_state.get_selected_entry()
            local fp = entry and (entry.path or entry.filename)
            if fp then
              table.insert(paths, "@" .. vim.fn.fnamemodify(fp, ":."))
            end
          end

          if #paths == 0 then
            return
          end

          local insert_text = table.concat(paths, " ")
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local line = vim.api.nvim_get_current_line()
          local new_line = line:sub(1, col) .. insert_text .. line:sub(col + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, { row, col + #insert_text })
          vim.cmd("startinsert")
        end)
        return true
      end,
    })
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Pick file(s) with smart_open (@path)" })
  vim.keymap.set("n", "<C-g>", function()
    require("telescope.builtin").live_grep({
      attach_mappings = function(prompt_bufnr, _)
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi = picker:get_multi_selection()
          actions.close(prompt_bufnr)

          local paths = {}
          if #multi > 0 then
            for _, entry in ipairs(multi) do
              local fp = entry.path or entry.filename
              if fp then
                table.insert(paths, "@" .. vim.fn.fnamemodify(fp, ":."))
              end
            end
          else
            local entry = action_state.get_selected_entry()
            local fp = entry and (entry.path or entry.filename)
            if fp then
              table.insert(paths, "@" .. vim.fn.fnamemodify(fp, ":."))
            end
          end

          if #paths == 0 then
            return
          end

          local insert_text = table.concat(paths, " ")
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local line = vim.api.nvim_get_current_line()
          local new_line = line:sub(1, col) .. insert_text .. line:sub(col + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, { row, col + #insert_text })
          vim.cmd("startinsert")
        end)
        return true
      end,
    })
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Pick file(s) with live_grep (@path)" })
  vim.keymap.set("n", "<leader>oll", function()
    local raw = vim.fn.systemlist("gh issue list --state open --json number,title,url --limit 400")
    if vim.v.shell_error ~= 0 then
      notify("Failed to run 'gh issue list'", vim.log.levels.ERROR)
      return
    end
    local ok, issues = pcall(vim.fn.json_decode, raw)
    if not ok or type(issues) ~= "table" or #issues == 0 then
      notify("No issues found", vim.log.levels.WARN)
      return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    pickers
      .new({}, {
        prompt_title = "Issues (insert link)",
        finder = finders.new_table({
          results = issues,
          entry_maker = function(issue)
            return {
              value = issue.url,
              display = string.format("#%d %s", issue.number, issue.title),
              ordinal = string.format("%d %s", issue.number, issue.title),
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          actions.select_default:replace(function()
            local picker = action_state.get_current_picker(prompt_bufnr)
            local multi = picker:get_multi_selection()
            actions.close(prompt_bufnr)

            local links = {}
            if #multi > 0 then
              for _, entry in ipairs(multi) do
                if entry.value then
                  table.insert(links, entry.value)
                end
              end
            else
              local entry = action_state.get_selected_entry()
              if entry and entry.value then
                table.insert(links, entry.value)
              end
            end

            if #links == 0 then
              return
            end

            local insert_text = table.concat(links, " ")
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            local line = vim.api.nvim_get_current_line()
            local new_line = line:sub(1, col) .. insert_text .. line:sub(col + 1)
            vim.api.nvim_set_current_line(new_line)
            vim.api.nvim_win_set_cursor(0, { row, col + #insert_text })
            vim.cmd("startinsert")
          end)
          return true
        end,
      })
      :find()
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Pick GitHub issue(s) and insert link" })
end

function M.focus_or_open(opts)
  opts = opts or {}

  local fallback_target_patterns = opts.fallback_target_patterns
    or state.get_fallback_target_patterns(M.fallback_target_patterns)
  local draft_bufnr = state.get_draft_bufnr()

  if draft_bufnr then
    if focus_existing_draft(draft_bufnr) then
      return true, "Focused existing draft buffer"
    end

    local target_bufnr = opts.target_bufnr
    if not state.is_valid_buf(target_bufnr) then
      target_bufnr = state.get_target_terminal_bufnr()
    end

    if use_float() then
      local via_target = open_float(draft_bufnr, target_bufnr, fallback_target_patterns, opts.draft_height)
      vim.cmd("startinsert")
      if not via_target then
        notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
      end
      return true, "Opened existing draft buffer"
    end

    local via_target = open_split_below_target(target_bufnr, fallback_target_patterns, opts.draft_height)
    vim.api.nvim_win_set_buf(0, draft_bufnr)
    resize_current_draft_window(opts.draft_height)
    vim.wo.winfixheight = true
    vim.cmd("startinsert")
    if not via_target then
      notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
    end
    return true, "Opened existing draft buffer"
  end

  local terminal_bufnr = opts.target_bufnr
  if not state.is_valid_buf(terminal_bufnr) then
    terminal_bufnr = resolve_target_terminal_bufnr(fallback_target_patterns)
  end
  if not state.is_valid_buf(terminal_bufnr) then
    return false, "Target terminal not found for draft buffer"
  end

  if use_float() then
    local _, via_target = M.open_for_target({
      target_bufnr = terminal_bufnr,
      fallback_target_patterns = fallback_target_patterns,
      draft_height = opts.draft_height,
    })
    if not via_target then
      notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
    end
    return true, "Opened draft buffer"
  end

  local via_target = open_split_below_target(terminal_bufnr, fallback_target_patterns, opts.draft_height)
  M.open_input_buffer({
    target_bufnr = terminal_bufnr,
    fallback_target_patterns = fallback_target_patterns,
    draft_height = opts.draft_height,
  })
  if not via_target then
    notify("Target terminal window not found; opened draft at bottom", vim.log.levels.WARN)
  end
  return true, "Opened draft buffer"
end

-- 現在タブの下書きバッファを用意し（無ければ作る）、ターゲット情報を登録して返す。
-- ウィンドウへの表示は呼び出し側（split / float）が行う。
function M.ensure_draft_buffer(opts)
  opts = opts or {}

  local bufnr = state.get_draft_bufnr()
  if not bufnr then
    bufnr = draft_buf.create_input_buffer("[Agent Input]")
    ensure_buffer_keymaps(bufnr)
    vim.b[bufnr].agent_input = true
  end

  state.set_draft_bufnr(bufnr)
  tab_bufnr_registry[vim.api.nvim_get_current_tabpage()] = bufnr
  if opts.target_bufnr and state.is_valid_buf(opts.target_bufnr) then
    state.set_target_terminal_bufnr(opts.target_bufnr)
  end
  state.set_fallback_target_patterns(opts.fallback_target_patterns)

  return bufnr
end

function M.open_input_buffer(opts)
  opts = opts or {}

  local bufnr = M.ensure_draft_buffer(opts)

  vim.api.nvim_win_set_buf(0, bufnr)
  resize_current_draft_window(opts.draft_height)
  vim.wo.winfixheight = true
  vim.cmd("startinsert")

  return bufnr
end

-- ターゲットのターミナルに対して下書きを開く（Agent タブ作成直後や AgentDraft から呼ぶ）。
-- 現在ウィンドウがターゲットのターミナルである前提。
-- float ならターミナルに重ね、split なら従来どおりターミナルの下に分割する。
-- ターミナルウィンドウが見つかったか（float のときのみ意味を持つ）を2つ目の戻り値で返す。
function M.open_for_target(opts)
  opts = opts or {}

  if use_float() then
    local bufnr = M.ensure_draft_buffer(opts)
    local via_target = open_float(bufnr, opts.target_bufnr, opts.fallback_target_patterns, opts.draft_height)
    vim.cmd("startinsert")
    return bufnr, via_target
  end

  vim.cmd("belowright split")
  return M.open_input_buffer(opts), true
end

function M.clear_draft()
  local bufnr = state.get_draft_bufnr()
  if not bufnr then
    return false, "Agent draft buffer not found"
  end

  draft_buf.clear(bufnr)
  return true, "Agent draft buffer cleared"
end

function M.hide()
  local bufnr = state.get_draft_bufnr()
  if not bufnr then
    return false, "Agent draft buffer not found"
  end

  local windows = vim.fn.win_findbuf(bufnr)
  if #windows == 0 then
    return false, "Agent draft buffer is not visible"
  end

  save_visible_draft_height(bufnr)

  local prev_winid = state.get_prev_winid()
  local fallback_winid
  local target_bufnr = state.get_target_terminal_bufnr()
  if state.is_valid_buf(target_bufnr) then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == target_bufnr then
        fallback_winid = winid
        break
      end
    end
  end

  for _, winid in ipairs(windows) do
    if vim.api.nvim_win_is_valid(winid) then
      pcall(vim.api.nvim_win_close, winid, false)
    end
  end

  local function try_focus(winid)
    if winid and vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_current_win(winid)
      return true
    end
    return false
  end

  if not try_focus(prev_winid) then
    try_focus(fallback_winid)
  end

  return true, "Agent draft buffer hidden"
end

function M.send_draft(opts)
  opts = opts or {}
  local hide_after
  if opts.hide_after == nil then
    hide_after = true
  else
    hide_after = opts.hide_after and true or false
  end

  local clear_input
  if opts.clear_input == nil then
    clear_input = true
  else
    clear_input = opts.clear_input and true or false
  end

  local draft_bufnr = state.get_draft_bufnr()
  if not draft_bufnr then
    local message = "Agent draft buffer not found"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local content = draft_buf.read_content(draft_bufnr)
  if content == "" then
    local message = "Draft is empty"
    notify(message, vim.log.levels.WARN)
    return false, message
  end

  local target_index
  local target_bufnr = state.get_target_terminal_bufnr()
  local fallback_target_patterns = state.get_fallback_target_patterns(M.fallback_target_patterns)
  if state.is_valid_buf(target_bufnr) then
    for index, term in ipairs(terminals.get_all_terminals()) do
      if term.bufnr == target_bufnr then
        target_index = index
        break
      end
    end
  end

  local target = target_index or fallback_target_patterns

  if hide_after then
    -- split を閉じるとターミナルが伸びて TUI が再描画されるので、それを待ってから送る。
    -- フロートはターミナルの大きさを変えないため待たない。
    local needs_resize_wait = has_split_window(draft_bufnr)
    M.hide()
    if needs_resize_wait then
      vim.cmd("redraw")
      vim.wait(350)
    end
  end

  if clear_input then
    local clear_seq = config.draft.clear_input_sequence
    if type(clear_seq) == "string" and clear_seq ~= "" then
      terminals.send_command(target, clear_seq, { add_newline = false, exclude_current = false, paste = false })
    end
  end

  local success, message =
    terminals.send_command(target, content, { add_newline = true, exclude_current = false, paste = true })
  if not success then
    notify(message, vim.log.levels.ERROR)
    return false, message
  end

  M.clear_draft()

  local focused_terminal = false
  if state.is_valid_buf(target_bufnr) then
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == target_bufnr then
        vim.api.nvim_set_current_win(winid)
        focused_terminal = true
        break
      end
    end
  end
  if focused_terminal then
    vim.cmd("startinsert")
  end

  return true, message
end

function M.quote_to_draft(lines, opts)
  opts = opts or {}

  local quoted = {}
  for _, line in ipairs(lines) do
    table.insert(quoted, "> " .. line)
  end

  local draft_bufnr = state.get_draft_bufnr()
  local need_open = draft_bufnr == nil or #vim.fn.win_findbuf(draft_bufnr) == 0

  if need_open then
    local success, message = M.focus_or_open({
      draft_height = opts.draft_height,
      fallback_target_patterns = opts.fallback_target_patterns,
      target_bufnr = opts.target_bufnr,
    })
    if not success then
      return false, message
    end
    draft_bufnr = state.get_draft_bufnr()
    if not draft_bufnr then
      return false, "Failed to create draft buffer"
    end
  end

  local existing = vim.api.nvim_buf_get_lines(draft_bufnr, 0, -1, false)
  local has_content = not (#existing == 0 or (#existing == 1 and existing[1] == ""))

  local to_append = {}
  if has_content then
    table.insert(to_append, "")
  end
  for _, q in ipairs(quoted) do
    table.insert(to_append, q)
  end
  table.insert(to_append, "")

  if has_content then
    vim.api.nvim_buf_set_lines(draft_bufnr, -1, -1, false, to_append)
  else
    vim.api.nvim_buf_set_lines(draft_bufnr, 0, -1, false, to_append)
  end

  if not need_open then
    for _, winid in ipairs(vim.fn.win_findbuf(draft_bufnr)) do
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_set_current_win(winid)
        break
      end
    end
  end
  local line_count = vim.api.nvim_buf_line_count(draft_bufnr)
  vim.api.nvim_win_set_cursor(0, { line_count, 0 })
  vim.cmd("startinsert|normal! $")

  return true, "Quoted " .. #quoted .. " lines to draft"
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  local group = vim.api.nvim_create_augroup("AgentInputTabCleanup", { clear = true })

  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = vim.api.nvim_create_augroup("AgentInputFloatReposition", { clear = true }),
    callback = function()
      M.reposition_floats()
    end,
  })

  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      local live_bufnrs = {}
      for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
        local ok, bufnr = pcall(vim.api.nvim_tabpage_get_var, tabpage, "agent_input_bufnr")
        if ok and state.is_valid_buf(bufnr) then
          live_bufnrs[bufnr] = true
        end
      end

      for tabpage, bufnr in pairs(tab_bufnr_registry) do
        if not vim.api.nvim_tabpage_is_valid(tabpage) then
          tab_bufnr_registry[tabpage] = nil
          if state.is_valid_buf(bufnr) and not live_bufnrs[bufnr] then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
        end
      end
    end,
  })
end

return M
