local dual_ai_config = {
  primary_command = "claude",
  secondary_command = "codex",
  draft_target_pattern = "claude",
  draft_height = 8,
  open_in_new_tab = true,
}

vim.api.nvim_create_user_command("CodexTerm", function(command)
  local codex_cmd = "codex"
  if command.args ~= "" then
    codex_cmd = codex_cmd .. " " .. command.args
  end

  vim.cmd("terminal " .. codex_cmd)
  local bufnr = vim.api.nvim_get_current_buf()

  -- Codex terminal: Ctrl+Enter sends command and returns to terminal-normal mode.
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = bufnr, noremap = true, silent = true })
end, { nargs = "*" })

local claude_input_ok, claude_input = pcall(require, "claude_input")
if claude_input_ok then
  claude_input.setup()

  vim.api.nvim_create_user_command("ClaudeDraftSend", function()
    -- send_draft は成功時に内部で clear + hide (default) を行う
    local success, message = claude_input.send_draft({ hide_after = true })
    if success then
      -- vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, { desc = "Send draft buffer to Claude terminal" })
  vim.api.nvim_create_user_command("ClaudeDraftClear", function()
    local success, message = claude_input.clear_draft()
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.WARN)
    end
  end, { desc = "Clear Claude draft buffer" })

  vim.api.nvim_create_user_command("TermDraft", function()
    local target_bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[target_bufnr].buftype ~= "terminal" then
      vim.notify("[TermDraft] Run this command from a terminal buffer", vim.log.levels.WARN)
      return
    end

    vim.cmd("belowright split")
    if dual_ai_config.draft_height and dual_ai_config.draft_height > 0 then
      vim.cmd("resize " .. tostring(dual_ai_config.draft_height))
    end

    claude_input.open_input_buffer({ claude_bufnr = target_bufnr })
  end, { desc = "Open draft buffer linked to current terminal" })

  local function find_claude_draft_winid()
    local draft_bufnr = vim.t.claude_input_bufnr
    if not draft_bufnr or not vim.api.nvim_buf_is_valid(draft_bufnr) then
      return nil
    end

    local windows = vim.fn.win_findbuf(draft_bufnr)
    for _, winid in ipairs(windows) do
      if vim.api.nvim_win_is_valid(winid) then
        return winid
      end
    end

    return nil
  end

  local function toggle_claude_draft_buffer()
    local current_winid = vim.api.nvim_get_current_win()
    local draft_winid = find_claude_draft_winid()

    -- claude-input 内から押下 → hide（フォーカス復帰は hide() 内部で処理）
    if draft_winid and draft_winid == current_winid then
      claude_input.hide()
      return
    end

    vim.t.claude_input_prev_winid = current_winid

    -- 可視ウィンドウがあればそこに focus
    if draft_winid then
      vim.api.nvim_set_current_win(draft_winid)
      vim.cmd("startinsert")
      return
    end

    -- ウィンドウが無い（初回 or hidden）→ target の下に再表示
    local current_bufnr = vim.api.nvim_get_current_buf()
    local focus_opts = {
      draft_height = dual_ai_config.draft_height,
      target_pattern = dual_ai_config.draft_target_pattern,
    }
    -- terminal から押された場合は current terminal に再リンク
    if vim.bo[current_bufnr].buftype == "terminal" then
      focus_opts.claude_bufnr = current_bufnr
      vim.t.claude_terminal_bufnr = current_bufnr
    end

    local success, message = claude_input.focus_or_open(focus_opts)
    if not success then
      vim.notify(message, vim.log.levels.WARN)
    end
  end

  vim.keymap.set({ "n", "i", "t", "v" }, "<M-a>", toggle_claude_draft_buffer, {
    noremap = true,
    silent = true,
    desc = "Toggle Claude draft buffer",
  })

  vim.api.nvim_create_user_command("ClaudeDraftQuote", function()
    local l1 = vim.fn.line("'<")
    local l2 = vim.fn.line("'>")

    local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)

    claude_input.quote_to_draft(lines, {
      draft_height = dual_ai_config.draft_height,
      target_pattern = dual_ai_config.draft_target_pattern,
    })
  end, { range = true, desc = "Quote selected text to Claude draft buffer" })

  vim.keymap.set("v", "<leader>iq", ":<C-u>ClaudeDraftQuote<CR>", {
    noremap = true,
    silent = true,
    desc = "Quote selection to Claude draft",
  })
end

-- Claude Code + Claude入力バッファ を2分割で起動
vim.api.nvim_create_user_command("ClaudeAI", function()
  vim.cmd("tabnew")
  vim.cmd("terminal " .. dual_ai_config.primary_command)
  local claude_bufnr = vim.api.nvim_get_current_buf()
  vim.t.claude_terminal_bufnr = claude_bufnr

  vim.cmd("belowright split")
  vim.cmd("resize " .. tostring(15))

  if claude_input_ok then
    claude_input.open_input_buffer({
      claude_bufnr = claude_bufnr,
      target_pattern = dual_ai_config.draft_target_pattern,
    })
  else
    vim.notify("[ClaudeAI] claude_input module not found", vim.log.levels.WARN)
    vim.cmd("enew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.filetype = "markdown"
    vim.cmd("startinsert")
  end
end, { desc = "Open Claude Code + Claude draft buffer" })

-- Claude Code / Codex / Claude入力バッファ を3分割で起動
vim.api.nvim_create_user_command("DualAI", function()
  if dual_ai_config.open_in_new_tab then
    vim.cmd("tabnew")
  end

  vim.cmd("terminal " .. dual_ai_config.primary_command)
  local claude_bufnr = vim.api.nvim_get_current_buf()
  vim.t.claude_terminal_bufnr = claude_bufnr

  vim.cmd("vsplit")
  vim.cmd("terminal " .. dual_ai_config.secondary_command)
  local codex_bufnr = vim.api.nvim_get_current_buf()
  vim.keymap.set("t", "<C-CR>", [[<C-\><C-n>A<CR><Esc>]], { buffer = codex_bufnr, noremap = true, silent = true })

  -- Claude側に戻って下段に入力バッファを開く
  vim.cmd("wincmd h")
  vim.cmd("belowright split")
  if dual_ai_config.draft_height and dual_ai_config.draft_height > 0 then
    vim.cmd("resize " .. tostring(dual_ai_config.draft_height))
  end

  if claude_input_ok then
    claude_input.open_input_buffer({
      claude_bufnr = claude_bufnr,
      target_pattern = dual_ai_config.draft_target_pattern,
    })
  else
    vim.notify("[DualAI] claude_input module not found", vim.log.levels.WARN)
    vim.cmd("enew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.filetype = "markdown"
    vim.cmd("startinsert")
  end
end, { desc = "Open Claude + Codex + Claude draft buffer" })

vim.keymap.set("n", "<leader>ai", ":DualAI<CR>", { noremap = true, silent = true, desc = "Open Claude Code + Codex" })

-- terminal_bridge: ターミナル間コマンド送信
local bridge_ok, terminal_bridge = pcall(require, "terminal_bridge")
if bridge_ok then
  -- ターミナル一覧表示
  vim.api.nvim_create_user_command("TermList", function()
    local terminals = terminal_bridge.get_all_terminals()
    if #terminals == 0 then
      vim.notify("No terminal buffers found", vim.log.levels.WARN)
      return
    end

    print("Terminal buffers:")
    for i, term in ipairs(terminals) do
      print(string.format("  [%d] bufnr=%d, name=%s", i, term.bufnr, term.name))
    end
  end, {
    desc = "List all terminal buffers",
  })

  -- ターミナルにコマンド送信
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

    local success, message = terminal_bridge.send_command(target, command)
    if success then
      vim.notify(message, vim.log.levels.INFO)
    else
      vim.notify(message, vim.log.levels.ERROR)
    end
  end, {
    nargs = "+",
    desc = "Send command to terminal by index",
  })
end

-- DualClaude: 2つのClaude Codeターミナル + 中央寄せ入力バッファ
local dual_claude_ok, dual_claude = pcall(require, "dual_claude")
if dual_claude_ok then
  vim.api.nvim_create_user_command("DualClaude", function()
    dual_claude.open()
  end, { desc = "Open dual Claude terminals with centered input" })

  vim.keymap.set("n", "<leader>aD", ":DualClaude<CR>", {
    noremap = true,
    silent = true,
    desc = "Open DualClaude",
  })
end

return {}
