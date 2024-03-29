local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- カラースキームの設定
config.color_scheme = "AdventureTime"

-- 背景透過
config.window_background_opacity = 0.85

config.initial_cols = 120
config.initial_rows = 60

-- ショートカットキー設定
local act = wezterm.action
config.keys = {
  -- Alt(Opt)+Shift+Fでフルスクリーン切り替え
  {
    key = "f",
    mods = "SHIFT|META",
    action = wezterm.action.ToggleFullScreen,
  },
}

return config
