local autocmd = vim.api.nvim_create_autocmd
local set_hl = vim.api.nvim_set_hl

vim.o.updatetime = 300

local function on_cursor_hold()
  if vim.bo.filetype ~= "NvimTree" and vim.api.nvim_get_mode().mode ~= "i" then
    vim.lsp.buf.hover()
  end
end

local lsp_hover_group = vim.api.nvim_create_augroup("lsp_hover", { clear = true })
-- autocmd({ "CursorHold", "CursorHoldI" }, {
--   pattern = "*",
--   group = lsp_hover_group,
--   callback = on_cursor_hold, -- ここで直接関数を指定
-- })

-- LSPのハイライトを設定
set_hl(0, "LspReferenceText", { underline = true, ctermfg = 1, ctermbg = 8, fg = "#A00000", bg = "#104040" })
set_hl(0, "LspReferenceRead", { underline = true, ctermfg = 1, ctermbg = 8, fg = "#A00000", bg = "#104040" })
set_hl(0, "LspReferenceWrite", { underline = true, ctermfg = 1, ctermbg = 8, fg = "#A00000", bg = "#104040" })

-- 自動ファイル保存
-- markdonw以外のファイルを自動で保存する
autocmd({ "BufLeave", "BufUnload", "CursorHold" }, {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype
    local buftype = vim.bo.buftype
    if filetype ~= "markdown" and buftype ~= "quickfix" then
      vim.cmd("silent! update")
    end
  end,
})

local function on_exit_cb(job_id, exit_code, event)
  -- コマンドが終了した後に何か処理を行いたい場合はここに書きます
  -- 例: コマンドの終了ログを表示
  print("memo commit finished with exit code", exit_code)
end

local function memo_commit_async()
  local handle
  -- memo commitコマンドを非同期に実行
  handle, _ = vim.loop.spawn(

    "memo",
    {
      args = { "commit" },
      stdio = { nil, nil, nil }, -- 標準入出力を無視
    },
    vim.schedule_wrap(function(code, signal)
      -- コマンド実行完了時のコールバック
      on_exit_cb(handle, code, signal)
    end)
  )
end

-- -- 自動コマンドを設定
-- vim.api.nvim_create_autocmd("BufWritePost", {
--   group = vim.api.nvim_create_augroup("MemoAutoCommit", { clear = true }),
--   pattern = "*/.memolist/memo/*.md",
--   callback = memo_commit_async,
-- })

-- luaファイル保存時に設定をリロード
autocmd("BufWritePost", { pattern = "*.lua", command = "source <afile> | echo 'Configuration reloaded!'" })

-- カーソルを画面中央になるようにする
autocmd("CursorMoved", { pattern = "*", command = "normal! zz" })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" and vim.v.event.regname == "" then
      vim.fn.setreg("*", vim.fn.getreg('"'))
      vim.fn.setreg("+", vim.fn.getreg('"'))
    end
  end,
})

local play_process_id = nil
-- 音声を再生する関数
local function play_sound()
  local filepath = vim.fn.expand("~/Downloads/VimJpRadio/20240902.mp3")
  play_process_id = vim.fn.jobstart('afplay "' .. filepath .. '"', { detach = true })
end

-- 音声を停止する関数
_G.stop_sound = function()
  if play_process_id then
    vim.fn.jobstop(play_process_id)
    play_process_id = nil
  end
end

-- toggle 音声再生
_G.toggle_sound = function()
  if play_process_id then
    stop_sound()
  else
    play_sound()
  end
end

-- キーマッピング（<leader>s で音声を停止）

-- vim.api.nvim_set_keymap("n", "<leader>s", ":lua toggle_sound()<CR>", { noremap = true, silent = true })

-- コメントアウト時の制御
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "markdown",
--   callback = function()
--     vim.opt_local.autoindent = true
--     vim.opt_local.formatoptions:append("r")
--     vim.opt_local.comments:append("b:-")
--   end,
-- })

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "markdown", "text", "tex", "latex" },
  callback = function()
    vim.keymap.set("n", "<leader>di", function()
      vim.diagnostic.open_float({
        border = "rounded",
        max_width = 80,
        source = true,
        format = function(diagnostic)
          return string.format("%s [%s]", diagnostic.message, diagnostic.source)
        end,
      })
    end)
  end,
})
