-- :terminal 内のエージェントが OSC 0/2 で設定したタイトル（b:term_title）を、
-- Neovim のタイトル（'title' / 'titlestring'）として外側の端末へ出す。
--
-- Neovim の :terminal は子プロセスのタイトルを b:term_title に保存するだけで外へ流さないため、
-- そのままでは外側の端末（Rex や herdr など）にエージェントのタスク名が出ない。
-- エージェントは「OSC 7501（Program Status Protocol）を出したバッファ」とみなす。
-- 普通のシェルの端末はタイトルを出しても数えない。

local M = {}

local OSC7501 = "\27]7501;"

-- エージェントになったバッファ（順番どおり）と、最後に触ったエージェント
local order = {}
local last = nil

local function sanitize(text)
  return (text:gsub("%c", " "))
end

-- 出すタイトルを決める。
-- state.agents:  { { buf, title }, ... }（タイトルを出したエージェント）
-- state.current: 今いるバッファ
-- state.last:    最後に触ったエージェント
function M.compute(state)
  local agents = state.agents or {}
  if #agents == 0 then
    return ""
  end

  local function find(buf)
    for _, agent in ipairs(agents) do
      if agent.buf == buf then
        return agent
      end
    end
  end

  local main = find(state.current) or (state.last and find(state.last)) or agents[1]
  local title = sanitize(main.title)
  if #agents > 1 then
    title = title .. (" (+%d)"):format(#agents - 1)
  end
  return title
end

local function collect()
  local agents = {}
  for _, buf in ipairs(order) do
    if vim.api.nvim_buf_is_valid(buf) then
      local title = vim.b[buf].term_title
      -- b:term_title は最初 "term://..." で初期化される。エージェントが出したものだけを使う
      if type(title) == "string" and title ~= "" and not title:match("^term://") then
        table.insert(agents, { buf = buf, title = title })
      end
    end
  end
  return agents
end

-- 'titlestring' から呼ばれる
function M.titlestring()
  return M.compute({ agents = collect(), current = vim.api.nvim_get_current_buf(), last = last })
end

local function is_agent(buf)
  return vim.tbl_contains(order, buf)
end

local function refresh()
  vim.schedule(function()
    -- 同じ値を設定し直して、タイトルを作り直させる
    vim.o.titlestring = vim.o.titlestring
  end)
end

-- opts.enabled: 有効にするか（agent_term/outer/init.lua が、送り先があるときに true を渡す）
function M.setup(opts)
  opts = opts or {}

  local group = vim.api.nvim_create_augroup("agent_term_outer_title", { clear = true })
  order = {}
  last = nil
  if not opts.enabled then
    return
  end

  vim.o.title = true
  vim.o.titlestring = "%{v:lua.require'agent_term.outer.title'.titlestring()}"

  vim.api.nvim_create_autocmd("TermRequest", {
    group = group,
    callback = function(ev)
      local sequence = ev.data and ev.data.sequence or ""
      local buf = ev.buf
      if sequence:sub(1, #OSC7501) == OSC7501 then
        if not is_agent(buf) then
          table.insert(order, buf)
        end
      elseif not (sequence:match("^\27%][02];") and is_agent(buf)) then
        return
      end
      if buf == vim.api.nvim_get_current_buf() then
        last = buf
      end
      refresh()
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      if is_agent(ev.buf) then
        last = ev.buf
        refresh()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TermClose", "BufWipeout" }, {
    group = group,
    callback = function(ev)
      if not is_agent(ev.buf) then
        return
      end
      order = vim.tbl_filter(function(buf)
        return buf ~= ev.buf
      end, order)
      if last == ev.buf then
        last = nil
      end
      refresh()
    end,
  })
end

return M
