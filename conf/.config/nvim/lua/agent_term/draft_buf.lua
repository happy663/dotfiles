-- draft.lua（ローカル宛の下書き）と send_to.lua（別ペイン宛の下書き）の共通部分。
-- どちらも「入力用のスクラッチバッファを作り、内容を読み、送信/クリアのキーを張る」
-- という同じ処理を持つため、ここへ切り出している。
local M = {}

-- 末尾の空行を落とす。送信時に余分な改行が agent へ届くのを防ぐ。
function M.trim_trailing_empty_lines(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines, #lines)
  end
  return lines
end

-- 入力用バッファを作る。name はバッファ名（表示用）。
function M.create_input_buffer(name)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "markdown"
  vim.bo[bufnr].modifiable = true
  return bufnr
end

-- バッファの内容を1つの文字列として返す。末尾の空行は落とす。空なら "" を返す。
function M.read_content(bufnr)
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  M.trim_trailing_empty_lines(lines)
  return table.concat(lines, "\n")
end

function M.clear(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  end
end

-- 送信/クリアのキーマップを張る。呼ぶコマンド名だけが呼び出し側で異なる。
-- cmds = { send = "AgentDraftSend", send_keep = "AgentDraftSend!", clear = "AgentDraftClear" }
function M.apply_send_keymaps(bufnr, cmds)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  vim.keymap.set(
    "n",
    "<C-CR>",
    "<Cmd>" .. cmds.send .. "<CR>",
    vim.tbl_extend("force", opts, { desc = "Send agent draft" })
  )
  vim.keymap.set(
    "i",
    "<C-CR>",
    "<Esc><Cmd>" .. cmds.send .. "<CR>",
    vim.tbl_extend("force", opts, { desc = "Send agent draft" })
  )
  vim.keymap.set(
    "n",
    "<leader>is",
    "<Cmd>" .. cmds.send .. "<CR>",
    vim.tbl_extend("force", opts, { desc = "Send agent draft" })
  )
  if cmds.send_keep then
    vim.keymap.set(
      "n",
      "<leader>iS",
      "<Cmd>" .. cmds.send_keep .. "<CR>",
      vim.tbl_extend("force", opts, { desc = "Send agent draft (keep terminal input)" })
    )
  end
  vim.keymap.set(
    "n",
    "<leader>ic",
    "<Cmd>" .. cmds.clear .. "<CR>",
    vim.tbl_extend("force", opts, { desc = "Clear agent draft" })
  )
end

return M
