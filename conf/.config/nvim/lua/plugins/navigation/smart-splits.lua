local function start_resize_mode()
  local smart_splits = require("smart-splits")
  local resize = {
    h = function()
      smart_splits.resize_left(1)
    end,
    j = function()
      smart_splits.resize_down(1)
    end,
    k = function()
      smart_splits.resize_up(1)
    end,
    l = function()
      smart_splits.resize_right(1)
    end,
  }

  vim.api.nvim_echo({ { "resize: h/j/k/l, Enter/Esc/q to finish", "ModeMsg" } }, false, {})

  while true do
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      break
    end

    if key == "\027" or key == "\r" or key == "\n" or key == "q" then
      break
    end

    local action = resize[key]
    if action then
      action()
      vim.cmd("redraw")
    end
  end

  vim.cmd("redraw")
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    cond = vim.g.not_in_vscode,
    init = function()
      vim.g.smart_splits_multiplexer_integration = "tmux"
    end,
    opts = {
      default_amount = 1,
      multiplexer_integration = "tmux",
    },
    keys = {
      { "<C-e>", start_resize_mode, mode = "n", desc = "Start smart resize mode" },
    },
  },
}
