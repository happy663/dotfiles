-- main.lua
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 他のモジュールをインポート
local appearance = require("appearance")
local keybindings = require("keybindings")
local events = require("events")
local commands = require("commands")

-- 設定を適用
appearance.apply(config)
keybindings.apply(config)
events.setup()
commands.setup()

-- WSL設定
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_domain = "WSL:Ubuntu-22.04"
end

return config
