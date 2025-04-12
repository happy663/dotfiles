-- appearance.lua
local wezterm = require("wezterm")
local M = {}

function M.apply(config)
  config.font = wezterm.font("HackGen Console NF", { weight = "Regular", stretch = "Normal", style = "Normal" })
  config.color_scheme = "AdventureTime"

  config.window_background_opacity = 0.6
  config.macos_window_background_blur = 1
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

  config.enable_kitty_graphics = true
  config.window_decorations = "RESIZE"

  config.show_new_tab_button_in_tab_bar = false
  config.show_close_tab_button_in_tabs = false

  config.colors = {
    tab_bar = {
      inactive_tab_edge = "none",
    },
  }

  -- 背景画像の設定
  -- M.setup_background_image(config)
end

function M.setup_background_image(config)
  local current_image_num = math.random(0, 11)

  local function build_image_path(image_num)
    local base_path = ""
    if wezterm.target_triple == "x86_64-pc-windows-msvc" then
      base_path = "C:/Users/toyama/.config/wezterm/images/wallpaperflare.com_wallpaper_"
    elseif wezterm.target_triple == "aarch64-apple-darwin" or wezterm.target_triple == "x86_64-apple-darwin" then
      base_path = wezterm.home_dir .. "/.config/wezterm/images/wallpaperflare.com_wallpaper_"
    end
    return base_path .. image_num .. ".jpg"
  end

  config.window_background_image = build_image_path(current_image_num)
end

return M
