local M = require("lualine.component"):extend()

function M:init(options)
  M.super.init(self, options)
end

function M:update_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

  if filetype ~= "codecompanion" then
    return nil
  end

  local ok_chat, Chat = pcall(require, "codecompanion.interactions.chat")
  if not ok_chat or not Chat.buf_get_chat then
    return nil
  end

  local ok_get, chat = pcall(Chat.buf_get_chat, bufnr)
  if not ok_get or not chat or not chat.acp_connection then
    return nil
  end

  local parts = {}

  -- モード情報
  local config_options = chat.acp_connection:get_config_options()
  local mode_opt = nil
  for _, opt in ipairs(config_options) do
    if opt.category == "mode" then
      mode_opt = opt
      break
    end
  end
  if mode_opt and mode_opt.currentValue then
    local mode_icons = {
      plan = "📋",
      default = "💬",
    }
    local icon = mode_icons[mode_opt.currentValue] or "🤖"
    table.insert(parts, icon .. " " .. mode_opt.currentValue)
  end

  -- モデル情報
  local models = chat.acp_connection:get_models()
  if models and models.currentModelId then
    -- Sonnetのidがdefaultだと分かりにくいので表示名を変換
    local model_names = {
      default = "sonnet",
      opus = "opus",
      haiku = "haiku",
    }
    local display_name = model_names[models.currentModelId] or models.currentModelId
    table.insert(parts, display_name)
  end

  if #parts > 0 then
    return table.concat(parts, " | ")
  end

  return nil
end

return M
