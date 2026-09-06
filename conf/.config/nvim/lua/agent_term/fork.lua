local M = {}

local SOURCES = { "claude", "pi" }
local REGISTRY_DIRS = {
  claude = "/tmp/claude-sessions",
  pi = "/tmp/pi-sessions",
}

local function read_session(source, pid)
  local file = io.open(REGISTRY_DIRS[source] .. "/" .. pid, "r")
  if not file then
    return nil
  end

  local session_id = file:read("*l")
  file:close()
  if session_id and session_id ~= "" then
    return session_id
  end
  return nil
end

local function children_by_parent()
  local handle = io.popen("ps -eo pid=,ppid= 2>/dev/null")
  if not handle then
    return {}
  end

  local children = {}
  for line in handle:lines() do
    local pid, ppid = line:match("^%s*(%d+)%s+(%d+)")
    if pid and ppid then
      children[ppid] = children[ppid] or {}
      table.insert(children[ppid], pid)
    end
  end
  handle:close()
  return children
end

function M.find_session(pid, requested_source, deps)
  deps = deps or {}
  local read_registered_session = deps.read_session or read_session
  local process_children = (deps.children_by_parent or children_by_parent)()
  local sources = requested_source and { requested_source } or SOURCES
  local queue = { tostring(pid) }
  local visited = {}

  while #queue > 0 do
    local current_pid = table.remove(queue, 1)
    if not visited[current_pid] then
      visited[current_pid] = true
      for _, source in ipairs(sources) do
        local session_id = read_registered_session(source, current_pid)
        if session_id then
          return source, session_id
        end
      end
      for _, child_pid in ipairs(process_children[current_pid] or {}) do
        table.insert(queue, tostring(child_pid))
      end
    end
  end

  return nil, nil
end

function M.build_split_command(source, session_id, cwd)
  local agent_command
  if source == "claude" then
    agent_command = "AgentClaude --resume " .. session_id .. " --fork-session"
  elseif source == "pi" then
    agent_command = "AgentPi --fork " .. session_id
  else
    error("Unsupported agent source: " .. tostring(source))
  end

  return string.format("tmux split-window -h -c %s \"nvim +'%s'\"", vim.fn.shellescape(cwd), agent_command)
end

function M.resolve_current(name, requested_source)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "terminal" then
    vim.notify("[" .. name .. "] Run from an agent terminal buffer", vim.log.levels.WARN)
    return nil, nil
  end

  local job_pid = vim.b[bufnr].terminal_job_pid
  if not job_pid then
    vim.notify("[" .. name .. "] No terminal job PID found", vim.log.levels.ERROR)
    return nil, nil
  end

  local source, session_id = M.find_session(job_pid, requested_source)
  if not session_id then
    local label = requested_source or "Claude/Pi"
    vim.notify("[" .. name .. "] No " .. label .. " session found for PID " .. job_pid, vim.log.levels.ERROR)
    return nil, nil
  end

  return source, session_id
end

function M.open(name, requested_source)
  local source, session_id = M.resolve_current(name, requested_source)
  if not session_id then
    return false
  end

  local command = M.build_split_command(source, session_id, vim.fn.getcwd())
  vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    vim.notify("[" .. name .. "] Failed to open tmux pane", vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
