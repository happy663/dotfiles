-- commands.lua
local wezterm = require("wezterm")
local M = {}

function M.setup()
  local hacky_user_commands = {
    ["new-ghosttext-window"] = function(window, pane, cmd_context)
      wezterm.GLOBAL.new_window_transparent = true
      local tab, _, new_window = wezterm.mux.spawn_window({
        args = { "zsh", "-l", "-c", "nvim -c GhostTextStart" },
        cwd = wezterm.home_dir,
        width = 60,
        height = 30,
        position = {
          x = 2400,
          y = 0,
        },
      })
      wezterm.GLOBAL.new_window_transparent = false
      new_window:set_title("GhostText")
    end,
  }

  wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "hacky-user-command" then
      local cmd_context = wezterm.json_parse(value)
      hacky_user_commands[cmd_context.cmd](window, pane, cmd_context)
      return
    end
  end)
end

return M
