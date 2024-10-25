-- keybindings.lua
local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

function M.apply(config)
  config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }
  config.keys = {
    -- ctrl+alt+tでnew tab
    { key = "t", mods = "LEADER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
    -- close
    { key = "w", mods = "LEADER", action = act({ CloseCurrentTab = { confirm = true } }) },
    { key = "V", mods = "SUPER", action = act.PasteFrom("Clipboard") },
    { key = "C", mods = "SUPER", action = act.CopyTo("Clipboard") },
    { key = "F", mods = "CTRL|SHIFT", action = act.ToggleFullScreen },
    { key = "R", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
    { key = "U", mods = "CTRL|SHIFT", action = act.EmitEvent("toggle-opacity-and-remove-background-image") },
    { key = "C", mods = "CTRL|SHIFT", action = act.EmitEvent("change-window-background-image") },
    { key = "w", mods = "ALT", action = act.HideApplication },
    -- Ctrl+Tab をNeovimに渡す
    { key = "Tab", mods = "CTRL", action = act({ SendString = "\x1b[27;5;9~" }) },
    -- Ctrl+Shift+Tab も同様に
    { key = "Tab", mods = "CTRL|SHIFT", action = act({ SendString = "\x1b[27;6;9~" }) },
    -- オプション4: Command/Ctrl + [ ]
    { key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
    { key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },
    -- Pane
    { key = "r", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "d", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },
    -- Pane移動 leader + hlkj
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    {
      mods = "LEADER",
      key = "s",
      action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
    },
    {
      --workspaceの名前変更
      key = "$",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "(wezterm) Set workspace title:",
        action = wezterm.action_callback(function(win, pane, line)
          if line then
            wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
          end
        end),
      }),
    },
    {
      key = "S",
      mods = "LEADER|SHIFT",
      action = act.PromptInputLine({
        description = "(wezterm) Create new workspace:",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:perform_aciton(
              act.SwitchToWorkspace({
                name = line,
              }),
              pane
            )
          end
        end),
      }),
    },
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  }

  config.macos_forward_to_ime_modifier_mask = "CTRL|SHIFT"
end

return M
