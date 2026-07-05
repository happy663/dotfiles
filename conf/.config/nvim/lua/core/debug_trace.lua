local M = {}

local namespace = vim.api.nvim_create_namespace("debug_trace")
local augroup = vim.api.nvim_create_augroup("DebugTrace", { clear = true })
local uv = vim.uv or vim.loop

local state = {
  active = false,
  started_at = nil,
  started_hrtime = nil,
  initial_messages = nil,
  initial_history_len = nil,
  events = {},
  pending_text = nil,
}

local function to_hex(value)
  local bytes = {}
  for i = 1, #value do
    table.insert(bytes, string.format("%02X", value:byte(i)))
  end
  return table.concat(bytes, " ")
end

local function key_label(value)
  if not value or value == "" then
    return nil
  end

  local ok, translated = pcall(vim.fn.keytrans, value)
  if not ok or translated == "" or translated:find("\239\191\189", 1, true) then
    return "<raw:" .. to_hex(value) .. ">"
  end

  return translated
end

local function now_iso()
  return os.date("%Y-%m-%d %H:%M:%S %z")
end

local function elapsed_ms()
  if not state.started_hrtime then
    return 0
  end
  return math.floor((uv.hrtime() - state.started_hrtime) / 1000000)
end

local function append_event(kind, fields)
  fields = fields or {}
  fields.t = elapsed_ms()
  fields.kind = kind
  table.insert(state.events, fields)
end

local function current_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)

  return {
    cwd = vim.fn.getcwd(),
    mode = vim.api.nvim_get_mode().mode,
    tab = vim.api.nvim_get_current_tabpage(),
    win = vim.api.nvim_get_current_win(),
    buf = bufnr,
    file = name ~= "" and name or "[No Name]",
    filetype = vim.bo[bufnr].filetype,
    buftype = vim.bo[bufnr].buftype,
    modified = vim.bo[bufnr].modified,
    cursor = cursor[1] .. ":" .. cursor[2],
  }
end

local function format_context(ctx)
  return {
    "- cwd: `" .. ctx.cwd .. "`",
    "- mode: `" .. ctx.mode .. "`",
    "- buffer: `" .. ctx.file .. "`",
    "- bufnr: `" .. ctx.buf .. "`",
    "- filetype: `" .. ctx.filetype .. "`",
    "- buftype: `" .. ctx.buftype .. "`",
    "- modified: `" .. tostring(ctx.modified) .. "`",
    "- cursor: `" .. ctx.cursor .. "`",
    "- tab/window: `" .. ctx.tab .. "` / `" .. ctx.win .. "`",
  }
end

local function launch_command()
  local argv = vim.v.argv or {}
  local parts = {}

  for _, arg in ipairs(argv) do
    table.insert(parts, vim.fn.shellescape(tostring(arg)))
  end

  if #parts == 0 then
    return "unknown"
  end

  return table.concat(parts, " ")
end

local function is_text_mode(mode)
  return mode:match("^[iR]") or mode:match("^t") or mode:match("^c")
end

local function is_plain_text_key(translated)
  return #translated == 1 or translated == "<Space>"
end

local function current_input_context(mode)
  local bufnr = vim.api.nvim_get_current_buf()
  local cmdtype = ""
  if mode:match("^c") then
    cmdtype = vim.fn.getcmdtype()
  end

  return {
    mode = mode,
    cmdtype = cmdtype,
    bufnr = bufnr,
    filetype = vim.bo[bufnr].filetype,
    buftype = vim.bo[bufnr].buftype,
  }
end

local function should_keep_text(context)
  if context.mode:match("^c") then
    return context.cmdtype == ":"
  end

  return context.buftype == "prompt" or context.filetype == "TelescopePrompt"
end

local function flush_pending_text()
  if not state.pending_text then
    return
  end

  append_event("typed", {
    mode = state.pending_text.mode,
    count = state.pending_text.count,
    text = state.pending_text.text,
    cmdtype = state.pending_text.cmdtype,
    filetype = state.pending_text.filetype,
    buftype = state.pending_text.buftype,
  })
  state.pending_text = nil
end

local function append_pending_text(context, translated)
  if
    state.pending_text
    and state.pending_text.mode == context.mode
    and state.pending_text.cmdtype == context.cmdtype
    and state.pending_text.bufnr == context.bufnr
  then
    state.pending_text.count = state.pending_text.count + 1
    if state.pending_text.text then
      state.pending_text.text = state.pending_text.text .. (translated == "<Space>" and " " or translated)
    end
    return
  end

  flush_pending_text()
  state.pending_text = {
    mode = context.mode,
    count = 1,
    text = should_keep_text(context) and (translated == "<Space>" and " " or translated) or nil,
    cmdtype = context.cmdtype,
    bufnr = context.bufnr,
    filetype = context.filetype,
    buftype = context.buftype,
  }
end

local function on_key(key, typed)
  if not typed or typed == "" then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  local translated = key_label(typed) or key_label(key) or "<unknown>"
  local context = current_input_context(mode)

  if is_text_mode(mode) and is_plain_text_key(translated) then
    append_pending_text(context, translated)
    return
  end

  flush_pending_text()
  append_event("key", {
    mode = mode,
    key = translated,
    cmdtype = context.cmdtype,
    filetype = context.filetype,
    buftype = context.buftype,
  })
end

local function setup_autocmds()
  vim.api.nvim_clear_autocmds({ group = augroup })

  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = augroup,
    callback = function(event)
      if not state.active then
        return
      end
      append_event(event.event, {
        buf = event.buf,
        file = vim.api.nvim_buf_get_name(event.buf),
        filetype = vim.bo[event.buf].filetype,
        buftype = vim.bo[event.buf].buftype,
      })
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(event)
      if not state.active then
        return
      end
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      append_event("LspAttach", {
        buf = event.buf,
        client = client and client.name or tostring(event.data.client_id),
      })
    end,
  })
end

local function messages_since_start()
  local messages = vim.split(vim.fn.execute("messages"), "\n", { plain = true })
  if not state.initial_messages then
    return messages
  end

  local start = #state.initial_messages + 1
  if start > #messages then
    return {}
  end

  local result = {}
  for i = start, #messages do
    table.insert(result, messages[i])
  end
  return result
end

local function command_history_since_start()
  local history_len = vim.fn.histnr(":")
  local start = (state.initial_history_len or history_len) + 1
  local lines = {}

  for i = start, history_len do
    local item = vim.fn.histget(":", i)
    if item and item ~= "" then
      table.insert(lines, string.format("%d  %s", i, item))
    end
  end

  return lines
end

local function loaded_lsp_clients()
  local lines = {}
  local clients = {}
  if vim.lsp.get_clients then
    clients = vim.lsp.get_clients({ bufnr = 0 })
  else
    clients = vim.lsp.get_active_clients({ bufnr = 0 })
  end

  for _, client in ipairs(clients) do
    table.insert(lines, "- `" .. client.name .. "`")
  end
  if #lines == 0 then
    return { "- none" }
  end
  return lines
end

local function diagnostics_summary()
  local severity = vim.diagnostic.severity
  local counts = {}

  if vim.diagnostic.count then
    counts = vim.diagnostic.count(0)
  else
    for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
      counts[diagnostic.severity] = (counts[diagnostic.severity] or 0) + 1
    end
  end

  return {
    "- errors: `" .. tostring(counts[severity.ERROR] or 0) .. "`",
    "- warnings: `" .. tostring(counts[severity.WARN] or 0) .. "`",
    "- info: `" .. tostring(counts[severity.INFO] or 0) .. "`",
    "- hints: `" .. tostring(counts[severity.HINT] or 0) .. "`",
  }
end

local function event_to_line(event)
  if event.kind == "typed" then
    if event.text then
      local prefix = event.cmdtype ~= "" and event.cmdtype or event.filetype
      return string.format("- +%dms [%s] <%s typed %q>", event.t, event.mode, prefix, event.text)
    end
    return string.format("- +%dms [%s] <typed %d chars>", event.t, event.mode, event.count)
  end
  if event.kind == "key" then
    if event.cmdtype and event.cmdtype ~= "" then
      return string.format("- +%dms [%s:%s] %s", event.t, event.mode, event.cmdtype, event.key)
    end
    return string.format("- +%dms [%s] %s", event.t, event.mode, event.key)
  end
  if event.kind == "BufEnter" then
    return string.format(
      "- +%dms BufEnter buf=%s `%s` ft=`%s` bt=`%s`",
      event.t,
      event.buf,
      event.file,
      event.filetype,
      event.buftype
    )
  end
  if event.kind == "FileType" then
    return string.format("- +%dms FileType `%s` file=`%s`", event.t, event.filetype, event.file)
  end
  if event.kind == "LspAttach" then
    return string.format("- +%dms LspAttach `%s` buf=%s", event.t, event.client, event.buf)
  end
  return "- +" .. event.t .. "ms " .. event.kind
end

local function build_report()
  local final_context = current_context()
  local version = vim.version()
  local lines = {
    "# Neovim Debug Trace",
    "",
    "## Metadata",
    "",
    "- started_at: `" .. state.started_at .. "`",
    "- stopped_at: `" .. now_iso() .. "`",
    "- duration_ms: `" .. elapsed_ms() .. "`",
    "- nvim: `" .. version.major .. "." .. version.minor .. "." .. version.patch .. "`",
    "- os: `" .. uv.os_uname().sysname .. " " .. uv.os_uname().release .. "`",
    "- launch_command: `" .. launch_command() .. "`",
    "",
    "## Initial Context",
    "",
  }

  vim.list_extend(lines, format_context(state.initial_context))
  vim.list_extend(lines, { "", "## Final Context", "" })
  vim.list_extend(lines, format_context(final_context))
  vim.list_extend(lines, { "", "## LSP Clients In Current Buffer", "" })
  vim.list_extend(lines, loaded_lsp_clients())
  vim.list_extend(lines, { "", "## Diagnostics In Current Buffer", "" })
  vim.list_extend(lines, diagnostics_summary())
  vim.list_extend(lines, { "", "## Key And Editor Events", "" })

  if #state.events == 0 then
    table.insert(lines, "- none")
  else
    for _, event in ipairs(state.events) do
      table.insert(lines, event_to_line(event))
    end
  end

  vim.list_extend(lines, { "", "## Command History Since Start", "" })
  local history = command_history_since_start()
  if #history == 0 then
    table.insert(lines, "none")
  else
    vim.list_extend(lines, history)
  end

  vim.list_extend(lines, { "", "## Messages Since Start", "" })
  local messages = messages_since_start()
  if #messages == 0 then
    table.insert(lines, "none")
  else
    vim.list_extend(lines, messages)
  end

  return lines
end

function M.start()
  if state.active then
    vim.notify("[DebugTrace] already active", vim.log.levels.WARN)
    return
  end

  state.active = true
  state.started_at = now_iso()
  state.started_hrtime = uv.hrtime()
  state.initial_context = current_context()
  state.initial_messages = vim.split(vim.fn.execute("messages"), "\n", { plain = true })
  state.initial_history_len = vim.fn.histnr(":")
  state.events = {}
  state.pending_text = nil

  setup_autocmds()
  vim.on_key(on_key, namespace)
  vim.notify("[DebugTrace] started", vim.log.levels.INFO)
end

function M.stop()
  if not state.active then
    vim.notify("[DebugTrace] not active", vim.log.levels.WARN)
    return
  end

  flush_pending_text()
  vim.on_key(nil, namespace)
  vim.api.nvim_clear_autocmds({ group = augroup })

  local path = string.format("/tmp/nvim-debug-trace-%s.md", os.date("%Y%m%d-%H%M%S"))
  vim.fn.writefile(build_report(), path)

  state.active = false
  vim.notify("[DebugTrace] wrote " .. path, vim.log.levels.INFO)
  print(path)
end

function M.setup()
  vim.api.nvim_create_user_command("DebugTraceStart", function()
    M.start()
  end, { desc = "Start recording a Neovim debug trace" })

  vim.api.nvim_create_user_command("DebugTraceStop", function()
    M.stop()
  end, { desc = "Stop recording a Neovim debug trace and write it to /tmp" })
end

return M
