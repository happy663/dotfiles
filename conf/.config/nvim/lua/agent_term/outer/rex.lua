-- Rex 向けの送り先（agent_term/outer/status.lua の sink）。
-- Rex は OSC 7501 を理解するので、報告をそのまま外側の端末へ転送する。
-- 1 つの Neovim に複数のエージェントがいても区別できるよう、バッファごとの id（agent/<bufnr>）を付ける。

local M = {}

local PREFIX = "\27]7501;"
local ST = "\27\\"
local ID_PREFIX = "agent/"

local function own_id(bufnr)
  return ID_PREFIX .. bufnr
end

-- バッファ bufnr の報告を、Rex へ送る文字列にする。pairs は書き換えない。
function M.encode(bufnr, pairs)
  local parts = {}
  local has_id = false
  for _, kv in ipairs(pairs) do
    local key, value = kv[1], kv[2]
    if key == "id" then
      value = own_id(bufnr) .. "/" .. value
      has_id = true
    end
    table.insert(parts, key .. "=" .. value)
  end
  if not has_id then
    -- id なしの報告（clear を含む）は、このバッファの記録として扱う
    table.insert(parts, "id=" .. own_id(bufnr))
  end
  return PREFIX .. table.concat(parts, ":") .. ST
end

-- Rex の中で、外側の端末へ書き出せるか
function M.available()
  return vim.env.REX_SESSION ~= nil and vim.env.REX_SESSION ~= "" and vim.api.nvim_ui_send ~= nil
end

-- opts.send: 転送に使う関数（既定: vim.api.nvim_ui_send）。テスト用
function M.new(opts)
  opts = opts or {}
  local send = opts.send or function(data)
    vim.api.nvim_ui_send(data)
  end
  return {
    report = function(bufnr, pairs)
      send(M.encode(bufnr, pairs))
    end,
    clear = function(bufnr)
      send(PREFIX .. "state=clear:id=" .. own_id(bufnr) .. ST)
    end,
  }
end

return M
