-- events.lua
local wezterm = require("wezterm")
local M = {}

-- Initialize the image number globally
local current_image_num = math.random(0, 11)

-- Function to build the image path
local function build_image_path(image_num)
  local base_path = ""
  if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    base_path = "C:/Users/toyama/.config/wezterm/images/wallpaperflare.com_wallpaper_"
  elseif wezterm.target_triple == "aarch64-apple-darwin" or wezterm.target_triple == "x86_64-apple-darwin" then
    base_path = wezterm.home_dir .. "/.config/wezterm/images/wallpaperflare.com_wallpaper_"
  end
  return base_path .. image_num .. ".jpg"
end

function M.setup()
  -- Fullscreen on startup
  wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():toggle_fullscreen()
  end)

  -- Toggle background opacity and image
  wezterm.on("toggle-opacity-and-remove-background-image", function(window)
    local overrides = window:get_config_overrides() or {}
    if not overrides.window_background_opacity then
      overrides.window_background_opacity = 0.5
      overrides.window_background_image = ""
    else
      overrides.window_background_opacity = nil
      overrides.window_background_image = build_image_path(current_image_num)
    end
    window:set_config_overrides(overrides)
  end)

  -- Change background image
  wezterm.on("change-window-background-image", function(window)
    current_image_num = math.random(0, 11)
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_image = build_image_path(current_image_num)
    window:set_config_overrides(overrides)
  end)

  -- Change background image
  wezterm.on("change-window-background-image-sakurai", function(window)
    current_image_num = 12
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_image = build_image_path(current_image_num)
    window:set_config_overrides(overrides)
  end)

  -- Window title formatting
  wezterm.on("format-window-title", function(tab, pane, tabs, panes)
    if tab.window_id == wezterm.GLOBAL.ghosttext_window_id then
      return "GhostText"
    end
    return "WezTerm"
  end)
end

local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"
  local edge_background = "none"
  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end
  local edge_foreground = background
  local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "
  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

return M
