-- :terminal 内のエージェントが出した OSC 7501（Program Status Protocol）を受け取り、
-- 外側の端末向けの送り先（sink）へ配る。
-- 仕様: https://www.superlogical.com/rex/docs/build/program-status
--
-- Neovim の :terminal は知らない OSC を外へ流さないため、エージェントの状態は外側の端末に届かない。
-- 送り先は環境ごとに用意する（agent_term/outer/init.lua が集める）。
--   sink.report(bufnr, pairs)  報告を受け取ったとき。pairs は { { key, value }, ... }
--   sink.clear(bufnr)          そのバッファのエージェントが居なくなったとき
--
-- Claude Code や Pi は起動時に対応確認（OSC 7501 ; ?）を送り、返事があったときだけ
-- OSC 7501 で状態を報告する。Neovim は返事をしないので、ここで代わりに返事をする。
-- 返事をするとエージェントはタイトルの状態記号を省くため、送り先がないときは返事をしない。

local M = {}

local PREFIX = "\27]7501;"
local ST = "\27\\"

-- 対応確認（OSC 7501 ; ?）かどうか
function M.is_query(sequence)
  return type(sequence) == "string" and sequence:sub(1, #PREFIX + 1) == PREFIX .. "?"
end

-- OSC 7501 の報告を { { key, value }, ... } にする。報告でなければ（対応確認も）nil。
function M.parse(sequence)
  if type(sequence) ~= "string" or sequence:sub(1, #PREFIX) ~= PREFIX or M.is_query(sequence) then
    return nil
  end
  local body = sequence:sub(#PREFIX + 1)
  body = body:gsub("\27\\$", "")
  body = body:gsub("\7$", "")

  local result = {}
  for pair in body:gmatch("[^:]+") do
    local key, value = pair:match("^%s*([a-z]+)%s*=%s*(.-)%s*$")
    if key then
      table.insert(result, { key, value })
    end
  end
  return result
end

local function default_reply(bufnr, data)
  local channel = vim.bo[bufnr].channel
  if channel and channel > 0 then
    pcall(vim.api.nvim_chan_send, channel, data)
  end
end

-- opts.sinks: 送り先の配列。空なら何もしない
-- opts.reply: 対応確認に返事をする関数 (bufnr, data)（既定: そのターミナルの入力へ送る）。テスト用
function M.setup(opts)
  opts = opts or {}
  local sinks = opts.sinks or {}
  local reply = opts.reply or default_reply

  local group = vim.api.nvim_create_augroup("agent_term_outer_status", { clear = true })
  if #sinks == 0 then
    return
  end

  -- 報告を配ったバッファ。閉じたときに送り先へ知らせるために覚えておく。
  -- Neovim 自体は動き続けるので、外側の端末からはエージェントの終了が見えない。
  local reported = {}

  local function clear_buffer(bufnr)
    if reported[bufnr] then
      reported[bufnr] = nil
      for _, sink in ipairs(sinks) do
        sink.clear(bufnr)
      end
    end
  end

  vim.api.nvim_create_autocmd("TermRequest", {
    group = group,
    callback = function(ev)
      local sequence = ev.data and ev.data.sequence
      if M.is_query(sequence) then
        -- 仕様の最小の返事（states / kinds を省くと、仕様の既定の一覧を意味する）
        reply(ev.buf, PREFIX .. "?" .. ST)
        return
      end
      local pairs = M.parse(sequence)
      if not pairs then
        return
      end
      reported[ev.buf] = true
      for _, sink in ipairs(sinks) do
        sink.report(ev.buf, vim.deepcopy(pairs))
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
      for _, bufnr in ipairs(vim.tbl_keys(reported)) do
        clear_buffer(bufnr)
      end
    end,
  })
end

return M
