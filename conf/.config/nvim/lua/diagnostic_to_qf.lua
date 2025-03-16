-- Luaファイル（例：~/.config/nvim/lua/diagnostic_to_qf.lua）に以下の関数を定義
local M = {}

-- すべてのバッファの診断情報をQuickfixリストに設定
function M.diagnostics_to_qf()
  vim.diagnostic.setqflist({ open = true })
end

-- 現在のバッファの診断情報をQuickfixリストに設定
function M.buffer_diagnostics_to_qf()
  vim.diagnostic.setqflist({ open = true, scope = "buffer" })
end

return M
