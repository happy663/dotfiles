local log = hs.logger.new("myLogger", "debug")
-- ~/.hammerspoon/modules/test.lua
hs.hotkey.bind({ "cmd", "alt" }, "T", function()
  hs.alert.show("テストモジュールが動作しています")
end)
