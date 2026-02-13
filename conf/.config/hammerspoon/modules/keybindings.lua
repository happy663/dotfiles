hs.alert.show("Keybindings loaded")

-- Ghostty launcher with Ctrl+W
hs.hotkey.bind({ "alt" }, "W", function()
  local app = hs.application.get("com.mitchellh.ghostty")
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.launchOrFocus("Ghostty")
  end
end)

hs.hotkey.bind({ "alt" }, "C", function()
  local app = hs.application.get("com.vivaldi.Vivaldi")
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.launchOrFocus("Chrome")
  end
end)

hs.hotkey.bind({ "alt" }, "S", function()
  local app = hs.application.get("com.tinyspeck.slackmacgap")
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.launchOrFocus("Slack")
  end
end)

hs.hotkey.bind({ "alt" }, "D", function()
  local app = hs.application.get("com.hnc.Discord")
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.launchOrFocus("Discord")
  end
end)
