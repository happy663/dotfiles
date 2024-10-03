-- keybindings.lua
local wezterm = require("wezterm")
local M = {}

function M.apply(config)
  config.keys = {
    { key = "V", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
    { key = "V", mods = "CTRL", action = wezterm.action.PasteFrom("PrimarySelection") },
    { key = "F", mods = "CTRL|SHIFT", action = wezterm.action.ToggleFullScreen },
    { key = "R", mods = "CTRL|SHIFT", action = wezterm.action.ReloadConfiguration },
    { key = "U", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("toggle-opacity-and-remove-background-image") },
    { key = "C", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("change-window-background-image") },
    { key = "w", mods = "ALT", action = wezterm.action.HideApplication },
    -- Ctrl+Tab をNeovimに渡す
    { key = "Tab", mods = "CTRL", action = wezterm.action({ SendString = "\x1b[27;5;9~" }) },
    -- Ctrl+Shift+Tab も同様に
    { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action({ SendString = "\x1b[27;6;9~" }) },
    -- オプション4: Command/Ctrl + [ ]
    { key = "[", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },
    { key = "]", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
  }

  config.macos_forward_to_ime_modifier_mask = "CTRL|SHIFT"
end

return M
