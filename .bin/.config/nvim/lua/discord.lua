local utils = require("utils")

local function send_to_discord(message)
  -- load_env("~/.config/nvim/.env")
  local webhook_url = vim.fn.getenv("DISCORD_WEBHOOK_URL")
  -- メッセージデータを作成
  local data = {
    content = message,
  }
  local json_data = vim.fn.json_encode(data)
  local curl_command =
    string.format("curl -X POST -H \"Content-Type: application/json\" -d '%s' %s", json_data, webhook_url)

  vim.notify("送信するJSON" .. json_data)

  local result = vim.fn.system(curl_command)

  if vim.v.shell_error ~= 0 then
    vim.notify("Discord送信エラー" .. result, vim.log.levels.ERROR)
  end

  vim.notify("messageを送信しました")
end

local function create_discord_buffer()
  vim.cmd("edit `=tempname()`")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = bufnr,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local content = table.concat(lines, "\n")
      if content ~= "" then
        send_to_discord(content)
      end
    end,
  })
end

local function process_discord(env_file_path)
  utils.load_env(env_file_path)
  return function()
    create_discord_buffer()
  end
end
local discord_buffer = process_discord("~/.config/nvim/.env")

vim.api.nvim_create_user_command("DiscordSendBuffer", discord_buffer, {
  desc = "Create Discord message buffer",
})

vim.keymap.set("n", "<leader>dsb", discord_buffer, {
  noremap = true,
  silent = true,
  desc = "Create Discord message buffer",
})

vim.api.nvim_create_user_command("DiscordSend", function(opts)
  local message = opts.args
  if message == "" then
    vim.notify("メッセージを入力してください")
    return
  end

  send_to_discord(message)
end, {
  nargs = "+",
  desc = "Send message to discord",
})

vim.keymap.set("n", "<leader>dsu", function()
  vim.ui.input({ prompt = "メッセージを入力してください" }, function(input)
    if input and input ~= "" then
      send_to_discord(input)
    end
  end)
end, { noremap = true, silent = true, desc = "Send message to discord" })
