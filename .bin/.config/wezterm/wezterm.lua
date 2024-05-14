-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Font and colorscheme settings
config.font = wezterm.font("HackGen Console NF", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.color_scheme = "AdventureTime"
wezterm.log_info(wezterm.target_triple)

-- Initialize the image number globally
local current_image_num = math.random(0, 11)

-- Function to build the image path
local function build_image_path(image_num)
  local base_path = ""
  if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    base_path = "C:/Users/toyama/.config/wezterm/images/wallpaperflare.com_wallpaper_"
  elseif wezterm.target_triple == "aarch64-apple-darwin" then
    base_path = wezterm.home_dir .. "/.config/wezterm/images/wallpaperflare.com_wallpaper_"
    print(base_path)
  end
  return base_path .. image_num .. ".jpg"
end

-- Set initial image
config.window_background_image = build_image_path(current_image_num)

-- Fullscreen on startup
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- Background opacity and blur settings
config.window_background_opacity = 1
config.macos_window_background_blur = 0
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

config.macos_forward_to_ime_modifier_mask = "CTRL|SHIFT"

-- Toggle background opacity and image
wezterm.on("toggle-opacity-and-remove-background-image", function(window)
  wezterm.log_info("toggle-opacity-and-remove-background-image")
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    wezterm.log_info("window_background_opacity is nil")
    overrides.window_background_opacity = 0.5
    overrides.window_background_image = ""
  else
    wezterm.log_info("window_background_opacity is not nil")
    overrides.window_background_opacity = nil
    overrides.window_background_image = build_image_path(current_image_num)
  end
  window:set_config_overrides(overrides)
end)

-- Change background image
wezterm.on("change-window-background-image", function(window)
  wezterm.log_info("change-window-background-image")
  current_image_num = math.random(0, 11) -- Update global image number
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_image = build_image_path(current_image_num)
  window:set_config_overrides(overrides)
end)

-- Key bindings
config.keys = {
  { key = "V", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
  { key = "V", mods = "CTRL", action = wezterm.action.PasteFrom("PrimarySelection") },
  { key = "f", mods = "CMD|SHIFT", action = wezterm.action.ToggleFullScreen },
  { key = "r", mods = "CMD|SHIFT", action = wezterm.action.ReloadConfiguration },
  { key = "U", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("toggle-opacity-and-remove-background-image") },
  { key = "I", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("change-window-background-image") },
}

return config
