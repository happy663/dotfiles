-- herdr のペインを 1 回のキーで動かす割合（herdr の pane resize は画面に対する割合で、既定 0.05・最大 0.5）。
-- smart-splits は nvim と同じく「1 マス」のつもりの量（default_amount = 1）を渡すので、ここで変換する。
local HERDR_RESIZE_STEP = 0.01

-- 外側のマルチプレクサ。herdr は新しいペインから TMUX を外すので、両方が同時に立つことはない（issue #351）
local function multiplexer()
  if vim.env.HERDR_ENV == "1" then
    return "herdr"
  end
  return "tmux"
end

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
    -- v2 の最終版。herdr との連携が本体に入っている（v3 では連携が別プラグインに分かれた）
    tag = "v2.1.1-final",
    lazy = false,
    cond = vim.g.not_in_vscode,
    init = function()
      vim.g.smart_splits_multiplexer_integration = multiplexer()
    end,
    opts = {
      default_amount = 1,
      multiplexer_integration = multiplexer(),
    },
    config = function(_, opts)
      require("smart-splits").setup(opts)
      if multiplexer() == "herdr" then
        local herdr = require("smart-splits.mux.herdr")
        local resize_pane = herdr.resize_pane
        herdr.resize_pane = function(direction, amount)
          return resize_pane(direction, HERDR_RESIZE_STEP * amount)
        end
      end
    end,
    keys = {
      { "<C-e>", start_resize_mode, mode = "n", desc = "Start smart resize mode" },
    },
  },
}
