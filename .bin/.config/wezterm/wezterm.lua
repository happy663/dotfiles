local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- カラースキームの設定
config.color_scheme = "AdventureTime"

-- 背景透過
config.window_background_opacity = 1

config.initial_cols = 120
config.initial_rows = 60

config.window_background_image =
  "/Users/toyama/src/github.com/dotfiles/.bin/.config/wezterm/images/wallpaperflare.com_wallpaper.jpg"

config.window_background_image_hsb = {
  -- Darken the background image by reducing it to 1/3rd
  brightness = 0.2,
  -- You can adjust the hue by scaling its value.
  -- a multiplier of 1.0 leaves the value unchanged.
  hue = 1,
  -- You can adjust the saturation also.
  saturation = 0.9,
}

config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.8,
}

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
