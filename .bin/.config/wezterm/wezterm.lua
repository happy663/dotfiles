-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "AdventureTime"
wezterm.log_info(wezterm.target_triple)

-- windows
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.window_background_image = "C:/Users/toyama/wallpaperflare.com_wallpaper.jpg"
  config.default_domain = "WSL:Ubuntu-22.04"
end

-- mac
if wezterm.target_triple == "x86_64-apple-darwin" then
  config.window_background_image =
    "/Users/toyama/src/github.com/dotfiles/.bin/.config/wezterm/images/wallpaperflare.com_wallpaper.jpg"
end

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- 背景透過
config.window_background_opacity = 1
config.initial_cols = 120
config.initial_rows = 60
config.window_background_image_hsb = {
  brightness = 0.2,
  hue = 1,
  saturation = 0.9,
}

config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.8,
}

local act = wezterm.action
config.keys = {
  -- paste from the clipboard
  { key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
  -- paste from the primary selection
  { key = "V", mods = "CTRL", action = act.PasteFrom("PrimarySelection") },
  -- Alt(Opt)+Shift+Fでフルスクリーン切り替え
  {
    key = "f",
    mods = "SHIFT|META",
    action = wezterm.action.ToggleFullScreen,
  },
}
-- and finally, return the configuration to wezterm
return config
