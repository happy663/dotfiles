-- :terminal 内のエージェントの状態とタイトルを、外側の端末（Neovim を動かしている端末）へ出す。
--
-- 環境ごとの送り先（sink）を集め、1 つもなければ何もしない。
-- 送り先がない環境で対応確認に返事をすると、エージェントがタイトルの状態記号を省き、
-- 外側の端末に状態の手がかりが残らなくなるため。
--
-- 送り先を足すときは、report(bufnr, pairs) / clear(bufnr) を持つ表を sinks に入れる
-- （例: agent_term/outer/rex.lua）。

local M = {}

local function collect_sinks()
  local sinks = {}
  local rex = require("agent_term.outer.rex")
  if rex.available() then
    table.insert(sinks, rex.new())
  end
  return sinks
end

function M.setup()
  local sinks = collect_sinks()
  require("agent_term.outer.status").setup({ sinks = sinks })
  require("agent_term.outer.title").setup({ enabled = #sinks > 0 })
end

return M
