local autocmd = vim.api.nvim_create_autocmd

vim.o.updatetime = 300

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

-- commit messageのテンプレートを開いたとき
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.fn.setpos(".", { 0, 7, 1, 0 })
    vim.api.nvim_buf_set_keymap(0, "n", "q", ":q<CR>", { noremap = true, silent = true })
  end,
})

-- ファイルが外部で変更されたら自動的に読み込む
vim.opt.autoread = true

-- フォーカスやバッファ切り替え時に自動チェック
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "AgenticChat" },
  callback = function()
    require("utils.markdown-helpers").setup_keymaps()

    -- ## 見出し間の移動キーバインド
    vim.keymap.set("n", "]]", function()
      vim.fn.search("^##  User\\s", "W")
    end, { buffer = true, desc = "Next ## heading" })

    vim.keymap.set("n", "[[", function()
      vim.fn.search("^##  User\\s", "bW")
    end, { buffer = true, desc = "Previous ## heading" })
  end,
})

local function apply_dir_based_colorscheme()
  require("utils").load_env(vim.env.DOTFILES_DIR .. "/.env")

  local default_dir_map_color_schema = {
    default = "tokyonight-moon",
  }
  local env_dir_map_color_schema = {}
  local dir_map_color_schema_json = vim.env.NVIM_DIR_MAP_COLOR_SCHEME or ""
  if dir_map_color_schema_json ~= "" then
    -- シングルクォートで囲まれている場合は除去
    dir_map_color_schema_json = dir_map_color_schema_json:gsub("^'(.*)'$", "%1")
    local ok, decoded = pcall(vim.json.decode, dir_map_color_schema_json)
    if ok and type(decoded) == "table" then
      env_dir_map_color_schema = decoded
    else
      vim.notify("NVIM_DIR_MAP_COLOR_SCHEME is not valid JSON", vim.log.levels.WARN)
    end
  end

  local current_dir_path = vim.fn.getcwd()
  local dir_name = string.match(current_dir_path, "([^/]+)$") or ""
  local selected_color_schema = env_dir_map_color_schema[dir_name]
    or env_dir_map_color_schema["default"]
    or default_dir_map_color_schema["default"]

  if vim.g.colors_name == selected_color_schema then
    return
  end

  print("Selected color schema:", selected_color_schema)
  vim.cmd("colorscheme " .. selected_color_schema)
end

local did_apply_dir_based_colorscheme = false
local function apply_dir_based_colorscheme_once()
  if did_apply_dir_based_colorscheme then
    return
  end
  did_apply_dir_based_colorscheme = true
  apply_dir_based_colorscheme()
end

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "",
  once = true,
  callback = function()
    -- vim.schedule(apply_dir_based_colorscheme_once)
    apply_dir_based_colorscheme()
  end,
})
