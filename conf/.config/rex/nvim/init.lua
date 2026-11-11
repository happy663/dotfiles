-- Neovim 側の Rex 連携の入り口。conf/.config/nvim/init.lua から、Rex の中にいるときだけ読み込まれる。
local dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local M = {}

function M.setup()
  -- エージェントの状態（OSC 7501）を Rex へ転送する
  dofile(dir .. "program_status.lua").setup()
  -- エージェントのタイトルを Neovim のタイトルとして Rex へ出す
  dofile(dir .. "agent_title.lua").setup()
end

return M
