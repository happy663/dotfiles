local agent_fork = require("agent_term.fork")
local cloud = require("agent_term.cloud")
local config = require("agent_term.config")
local draft = require("agent_term.local.draft")
local layouts = require("agent_term.layouts")
local routing = require("agent_term.local.routing")
local send_to = require("agent_term.picker.send_to")
local state = require("agent_term.local.state")
local terminals = require("agent_term.local.terminals")

local M = {}
local setup_done = false

local function find_draft_winid()
  local draft_bufnr = state.get_draft_bufnr()
  if not draft_bufnr then
    return nil
  end

  for _, winid in ipairs(vim.fn.win_findbuf(draft_bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      return winid
    end
  end

  return nil
end

local function toggle_draft_buffer()
  local current_winid = vim.api.nvim_get_current_win()
  local draft_winid = find_draft_winid()

  if draft_winid and draft_winid == current_winid then
    draft.hide()
    return
  end

  state.set_prev_winid(current_winid)

  if draft_winid then
    vim.api.nvim_set_current_win(draft_winid)
    vim.cmd("startinsert")
    return
  end

  -- 現在タブに Agent ドラフトが無い場合は、別タブの Agent ドラフトへ移動する（要望2）。
  -- Agent タブが見つからなければ、従来どおり現在タブで fallback して開く。
  if not state.get_draft_bufnr() then
    if routing.goto_agent_draft() then
      return
    end
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local focus_opts = {
    draft_height = config.draft.attached_height,
    fallback_target_patterns = config.draft.fallback_target_patterns,
  }
  if vim.bo[current_bufnr].buftype == "terminal" then
    focus_opts.target_bufnr = current_bufnr
    state.set_target_terminal_bufnr(current_bufnr)
  end

  local success, message = draft.focus_or_open(focus_opts)
  if not success then
    vim.notify(message, vim.log.levels.WARN)
  end
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  draft.setup()
  routing.setup()

  vim.api.nvim_create_user_command("AgentCodex", function(command)
    layouts.open_agent_codex({
      args = command.args,
      open_draft = true,
    })
  end, { nargs = "*", desc = "Open Codex agent terminal" })

  vim.api.nvim_create_user_command("AgentPi", function(command)
    layouts.open_agent_pi({
      args = command.args,
      open_draft = true,
    })
  end, { nargs = "*", desc = "Open pi agent terminal" })

  vim.api.nvim_create_user_command("AgentDraftSend", function(cmd_opts)
    local success, message = draft.send_draft({
      hide_after = true,
      clear_input = not cmd_opts.bang,
    })
    if not success then
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, { bang = true, desc = "Send agent draft buffer to target terminal (! to keep terminal input)" })

  vim.api.nvim_create_user_command("AgentDraftClear", function()
    local success, message = draft.clear_draft()
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Clear agent draft buffer" })

  vim.api.nvim_create_user_command("AgentDraft", function()
    layouts.open_term_draft({ draft_height = config.draft.attached_height })
  end, { desc = "Open agent draft buffer linked to current terminal" })

  vim.keymap.set({ "n", "i", "t", "v" }, "<M-a>", toggle_draft_buffer, {
    noremap = true,
    silent = true,
    desc = "Toggle agent draft buffer",
  })

  vim.api.nvim_create_user_command("AgentDraftQuote", function()
    local pos1 = vim.fn.getpos("'<")
    local pos2 = vim.fn.getpos("'>")
    local region_type = vim.fn.visualmode()
    local lines = vim.fn.getregion(pos1, pos2, { type = region_type })

    draft.quote_to_draft(lines, {
      draft_height = config.draft.attached_height,
      fallback_target_patterns = config.draft.fallback_target_patterns,
    })
  end, { range = true, desc = "Quote selected text to agent draft buffer" })

  vim.keymap.set("v", "<leader>iq", ":<C-u>AgentDraftQuote<CR>", {
    noremap = true,
    silent = true,
    desc = "Quote selection to agent draft",
  })

  vim.keymap.set({ "n", "v" }, "<leader>>", ":<C-u>AgentDraftQuote<CR>", {
    noremap = true,
    silent = true,
    desc = "Quote selection to agent draft",
  })

  vim.api.nvim_create_user_command("AgentClaude", function(command)
    layouts.open_agent_claude({
      args = command.args,
      open_draft = true,
    })
  end, { nargs = "*", desc = "Open Claude agent terminal + draft buffer" })

  -- クラウドの Claude Code セッションを入力バッファ経由で作る。シェルで日本語を
  -- 打てないため、説明（= 初回プロンプト）を nvim 側で書けるようにしている。
  vim.api.nvim_create_user_command("AgentClaudeCloud", function(command)
    cloud.open(command.args)
  end, { nargs = "?", desc = "Open input buffer to create a cloud Claude Code session (arg: worktree name)" })

  vim.api.nvim_create_user_command("AgentClaudeCloudCreate", function()
    cloud.create()
  end, { desc = "Create a cloud Claude session from the input buffer and teleport into it" })

  vim.api.nvim_create_user_command("AgentClaudeCloudClear", function()
    cloud.clear()
  end, { desc = "Clear the cloud session input buffer" })

  vim.api.nvim_create_user_command("AgentClaudeSession", function()
    layouts.open_agent_claude({
      command = "ccsession",
      fallback_target_patterns = { "claude", "ccsession" },
      open_draft = false,
    })
  end, { desc = "Open Claude session picker terminal" })

  vim.api.nvim_create_user_command("AgentFork", function()
    agent_fork.open("AgentFork")
  end, { desc = "Fork current Claude or Pi session into a new tmux pane with nvim" })

  vim.api.nvim_create_user_command("AgentClaudeFork", function()
    agent_fork.open("AgentClaudeFork", "claude")
  end, { desc = "Fork current Claude session into a new tmux pane with nvim" })

  vim.api.nvim_create_user_command("AgentPiFork", function()
    agent_fork.open("AgentPiFork", "pi")
  end, { desc = "Fork current Pi session into a new tmux pane with nvim" })

  vim.keymap.set("n", "<leader>ak", ":AgentFork<CR>", { desc = "AgentFork", noremap = true, silent = true })

  vim.api.nvim_create_user_command("AgentClaudeLogConversation", function()
    local _, session_id = agent_fork.resolve_current("AgentClaudeLogConversation", "claude")
    if not session_id then
      return
    end

    local cwd = vim.fn.getcwd()
    -- 現在のペインを分割して fork 先 Claude を起動し、/log-ai-conversation を実行させる。
    -- prompt 引数でスキルを呼ぶだけで、スキル本文が指示として機能する（fork 元の文脈には引きずられない）。
    -- 完了後の自動終了はしない（ユーザーが確認後にペインを閉じる）。
    local fork_prompt = "/log-ai-conversation"
    local inner = string.format("claude --resume %s --fork-session %s", session_id, vim.fn.shellescape(fork_prompt))
    local cmd = string.format("tmux split-window -h -c %s %s", vim.fn.shellescape(cwd), vim.fn.shellescape(inner))
    vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("[AgentClaudeLogConversation] Failed to open tmux pane", vim.log.levels.ERROR)
      return
    end
    vim.notify("[AgentClaudeLogConversation] Forked log-ai-conversation into a new pane", vim.log.levels.INFO)
  end, { desc = "Fork Claude session into a split pane and run log-ai-conversation" })

  vim.api.nvim_create_user_command("AgentClaudeRestart", function()
    local _, session_id = agent_fork.resolve_current("AgentClaudeRestart", "claude")
    if not session_id then
      return
    end

    local winid = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()
    local job_id = vim.b[bufnr].terminal_job_id
    if job_id then
      vim.fn.jobstop(job_id)
    end

    vim.api.nvim_set_current_win(winid)
    vim.cmd("enew")
    local resume_cmd = "claude --resume " .. session_id
    vim.cmd("terminal " .. resume_cmd)
    local new_bufnr = vim.api.nvim_get_current_buf()
    state.set_target_terminal_bufnr(new_bufnr)
    vim.cmd("startinsert")
  end, { desc = "Restart Claude Code with --resume in the same window" })

  vim.keymap.set(
    "n",
    "<leader>aj",
    ":AgentClaudeRestart<CR>",
    { desc = "AgentClaudeRestart", noremap = true, silent = true }
  )

  vim.api.nvim_create_user_command("AgentCodexSession", function()
    layouts.open_agent_codex({
      command = "ccsession --codex",
      open_draft = false,
    })
  end, { desc = "Open Codex session picker terminal" })

  vim.api.nvim_create_user_command("AgentPiSession", function()
    layouts.open_agent_pi({
      command = "ccsession --pi",
      open_draft = false,
    })
  end, { desc = "Open pi session picker terminal" })

  vim.api.nvim_create_user_command("AgentSession", function()
    layouts.open_agent_claude({
      command = "ccsession --all",
      open_draft = false,
    })
  end, { desc = "Open cross-source (Claude/Codex/Pi) session picker terminal" })

  vim.api.nvim_create_user_command("AgentClaudeCodex", function(command)
    layouts.open_agent_claude_codex({ args = command.args })
  end, { nargs = "*", desc = "Open Claude + Codex agent terminals + draft buffer" })

  vim.keymap.set("n", "<leader>ai", ":AgentClaudeCodex<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Claude + Codex agent terminals",
  })

  vim.api.nvim_create_user_command("TermList", function()
    local terms = terminals.get_all_terminals()
    if #terms == 0 then
      vim.notify("No terminal buffers found", vim.log.levels.WARN)
      return
    end

    print("Terminal buffers:")
    for i, term in ipairs(terms) do
      print(string.format("  [%d] bufnr=%d, name=%s", i, term.bufnr, term.name))
    end
  end, { desc = "List all terminal buffers" })

  vim.api.nvim_create_user_command("TermSend", function(cmd_opts)
    local args = vim.split(cmd_opts.args, " ", { plain = true })
    if #args < 2 then
      vim.notify("Usage: TermSend <index> <command>", vim.log.levels.ERROR)
      return
    end

    local target = tonumber(args[1])
    if not target then
      vim.notify("Invalid target index: " .. args[1], vim.log.levels.ERROR)
      return
    end

    local command = table.concat(vim.list_slice(args, 2), " ")
    local success, message = terminals.send_command(target, command)
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, { nargs = "+", desc = "Send command to terminal by index" })

  vim.api.nvim_create_user_command("AgentClaudePair", function(command)
    layouts.open_agent_claude_pair({ args = command.args })
  end, { nargs = "*", desc = "Open two Claude agent terminals with centered input" })

  vim.keymap.set("n", "<leader>aD", ":AgentClaudePair<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Claude agent pair",
  })

  -- 別ペインの Agent へ、ペインを移動せずにプロンプトを送る（issue #316）。
  -- ローカル宛は従来どおり <M-a>。
  vim.api.nvim_create_user_command("AgentSendTo", function()
    local success, message = send_to.open()
    if not success then
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Open agent picker and draft for another pane" })

  vim.api.nvim_create_user_command("AgentSendToToggle", function()
    local success, message = send_to.toggle()
    if not success then
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Toggle the agent send-to picker" })

  vim.api.nvim_create_user_command("AgentSendToSend", function()
    send_to.send()
  end, { desc = "Send draft to the selected agent pane" })

  vim.api.nvim_create_user_command("AgentSendToClear", function()
    send_to.clear()
  end, { desc = "Clear the send-to draft buffer" })

  vim.api.nvim_create_user_command("AgentSendToClose", function()
    send_to.close()
  end, { desc = "Close the send-to picker" })

  vim.api.nvim_create_user_command("AgentSendToJump", function()
    send_to.jump()
  end, { desc = "Jump to the selected agent pane" })

  vim.api.nvim_create_user_command("AgentSendToNext", function()
    send_to.select_next()
  end, { desc = "Select the next agent in the send-to picker" })

  vim.api.nvim_create_user_command("AgentSendToPrev", function()
    send_to.select_prev()
  end, { desc = "Select the previous agent in the send-to picker" })

  vim.api.nvim_create_user_command("AgentSendToRefresh", function()
    local success, message = send_to.refresh()
    if not success then
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Refresh the send-to agent list" })

  -- プレビューの操作（issue #318）。スクロールはプレビューにフォーカスを移さず、
  -- 下書き/一覧のキーマップから遠隔で行う。
  -- プレビューを出せない幅では何もせずに戻る。キーごとに通知すると煩いため黙って無視する。
  for _, spec in ipairs({
    { "AgentSendToPreviewUp", "preview_scroll_up", "Scroll the agent preview up" },
    { "AgentSendToPreviewDown", "preview_scroll_down", "Scroll the agent preview down" },
    { "AgentSendToPreviewFollow", "preview_follow", "Follow the agent preview" },
    { "AgentSendToPreviewLeft", "preview_scroll_left", "Scroll the agent preview left" },
    { "AgentSendToPreviewRight", "preview_scroll_right", "Scroll the agent preview right" },
  }) do
    vim.api.nvim_create_user_command(spec[1], function()
      send_to[spec[2]]()
    end, { desc = spec[3] })
  end

  -- 凍結中でも強制的に取り直す。
  vim.api.nvim_create_user_command("AgentSendToPreviewRefresh", function()
    local success, message = send_to.refresh_preview()
    if not success then
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Refresh the agent preview" })

  vim.keymap.set({ "n", "i", "t", "v" }, "<M-v>", "<Cmd>AgentSendToToggle<CR>", {
    noremap = true,
    silent = true,
    desc = "Send prompt to an agent in another pane",
  })
end

return M
