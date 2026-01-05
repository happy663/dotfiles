local M = require("lualine.component"):extend()

local spinner_symbols = {
  "🌑",
  "🌒",
  "🌓",
  "🌔",
  "🌕",
  "🌖",
  "🌗",
  "🌘",
}
local spinner_symbols_len = #spinner_symbols

M.spinner_index = 1

function M:init(options)
  M.super.init(self, options)

  local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

  local companion_buf
  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequest*",
    group = group,
    callback = function(request)
      local bufnr = vim.api.nvim_get_current_buf()
      if request.match == "CodeCompanionRequestStarted" then
        companion_buf = bufnr
        pcall(vim.api.nvim_buf_set_var, companion_buf, "cc_processing", true)
        vim.notify("Request Started (buf: " .. bufnr .. ")", vim.log.levels.DEBUG)
      elseif request.match == "CodeCompanionRequestFinished" then
        pcall(vim.api.nvim_buf_set_var, companion_buf, "cc_processing", false)
        vim.notify("Request Finished", vim.log.levels.DEBUG)
        companion_buf = nil
      end
    end,
  })
end

function M:update_status()
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- スピナー表示（既存）
  local ok, cc_proc = pcall(vim.api.nvim_buf_get_var, bufnr, "cc_processing")
  local spinner = ""
  if ok and cc_proc then
    self.spinner_index = (self.spinner_index % spinner_symbols_len) + 1
    spinner = spinner_symbols[self.spinner_index] .. " "
  end
  
  -- モード表示（新規）
  local mode_info = ""
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  
  if filetype == "codecompanion" then
    local ok_chat, Chat = pcall(require, "codecompanion.interactions.chat")
    if ok_chat and Chat.buf_get_chat then
      local ok_get, chat = pcall(Chat.buf_get_chat, bufnr)
      if ok_get and chat and chat.acp_connection then
        local modes = chat.acp_connection:get_modes()
        if modes and modes.currentModeId then
          local mode_icons = {
            plan = "📋",
            default = "💬",
          }
          local icon = mode_icons[modes.currentModeId] or "🤖"
          mode_info = string.format("%s %s", icon, modes.currentModeId)
        end
      end
    end
  end
  
  -- 結合して返す
  if spinner ~= "" or mode_info ~= "" then
    return spinner .. mode_info
  else
    return nil
  end
end

return M
