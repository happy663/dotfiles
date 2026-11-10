-- Neovim の :terminal 内のプログラム（Claude Code など）が出した OSC 7501
-- （Program Status Protocol）を受け取り、外側の端末（Rex）へ転送する。
-- 仕様: https://www.superlogical.com/rex/docs/build/program-status
--
-- Neovim の :terminal は知らない OSC を外へ流さないため、そのままでは Rex に届かない。
-- 1 つの Neovim に複数のエージェントがいても区別できるよう、報告には
-- バッファごとの id（agent/<bufnr>）を付けてから転送する。

local M = {}

local PREFIX = "\27]7501;"
local ST = "\27\\"
local ID_PREFIX = "agent/"

-- OSC 7501 の報告を { { key, value }, ... } にする。報告でなければ nil。
function M.parse(sequence)
  if type(sequence) ~= "string" or sequence:sub(1, #PREFIX) ~= PREFIX then
    return nil
  end
  local body = sequence:sub(#PREFIX + 1)
  body = body:gsub("\27\\$", "")
  body = body:gsub("\7$", "")
  -- 機能検出の問い合わせ（OSC 7501 ; ?）は転送しない
  if body:sub(1, 1) == "?" then
    return nil
  end

  local result = {}
  for pair in body:gmatch("[^:]+") do
    local key, value = pair:match("^%s*([a-z]+)%s*=%s*(.-)%s*$")
    if key then
      table.insert(result, { key, value })
    end
  end
  return result
end

local function encode(pairs_)
  local parts = {}
  for _, kv in ipairs(pairs_) do
    table.insert(parts, kv[1] .. "=" .. kv[2])
  end
  return PREFIX .. table.concat(parts, ":") .. ST
end

local function own_id(bufnr)
  return ID_PREFIX .. bufnr
end

-- バッファ bufnr の端末から届いたシーケンスを、転送用の文字列にする。
-- 転送しないものは nil。
function M.handle(bufnr, sequence)
  local pairs_ = M.parse(sequence)
  if not pairs_ then
    return nil
  end

  local has_id = false
  for _, kv in ipairs(pairs_) do
    if kv[1] == "id" then
      kv[2] = own_id(bufnr) .. "/" .. kv[2]
      has_id = true
    end
  end
  if not has_id then
    -- id なしの報告（clear を含む）は、このバッファの記録として扱う
    table.insert(pairs_, { "id", own_id(bufnr) })
  end
  return encode(pairs_)
end

local function default_enabled()
  return vim.env.REX_SESSION ~= nil and vim.env.REX_SESSION ~= "" and vim.api.nvim_ui_send ~= nil
end

-- opts.enabled: 転送するか（既定: Rex の中で、nvim_ui_send が使えるとき）
-- opts.send:    転送に使う関数（既定: vim.api.nvim_ui_send）。テスト用。
function M.setup(opts)
  opts = opts or {}
  local enabled = opts.enabled
  if enabled == nil then
    enabled = default_enabled()
  end
  local send = opts.send or function(data)
    vim.api.nvim_ui_send(data)
  end

  local group = vim.api.nvim_create_augroup("rex_program_status", { clear = true })
  if not enabled then
    return
  end

  -- 転送したことがあるバッファ。閉じたときにその記録を消すために覚えておく。
  -- Neovim 自体は動き続けるので、Rex からはエージェントの終了が見えない。
  local forwarded = {}

  local function clear_buffer(bufnr)
    if forwarded[bufnr] then
      forwarded[bufnr] = nil
      send(PREFIX .. "state=clear:id=" .. own_id(bufnr) .. ST)
    end
  end

  vim.api.nvim_create_autocmd("TermRequest", {
    group = group,
    callback = function(ev)
      local data = M.handle(ev.buf, ev.data and ev.data.sequence)
      if data then
        forwarded[ev.buf] = true
        send(data)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TermClose", "BufWipeout" }, {
    group = group,
    callback = function(ev)
      clear_buffer(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for _, bufnr in ipairs(vim.tbl_keys(forwarded)) do
        clear_buffer(bufnr)
      end
    end,
  })
end

return M
