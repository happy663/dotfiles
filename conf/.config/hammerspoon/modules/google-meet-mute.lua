local logger = hs.logger.new("google-meet-mute", "info")

hs.alert.show("Google Meet ミュートモジュールを読み込みました")

local isMuted = false

local function toggleGoogleMeetMute()
  local meet = hs.application.find("Google Meet")

  if not meet then
    hs.alert.show("⚠️ Google Meet が起動していません")
    logger.w("Google Meet application not found")
    return
  end

  local currentApp = hs.application.frontmostApplication()

  meet:activate()

  hs.timer.doAfter(0.05, function()
    hs.eventtap.keyStroke({ "cmd" }, "d", 0, meet)

    isMuted = not isMuted

    hs.timer.doAfter(0.05, function()
      if currentApp and currentApp:isRunning() then
        currentApp:activate()
      end

      if isMuted then
        hs.alert.show("🔇 Google Meet ミュート: ON", nil, nil, 1.5)
        logger.i("Google Meet muted")
      else
        hs.alert.show("🎤 Google Meet ミュート: OFF", nil, nil, 1.5)
        logger.i("Google Meet unmuted")
      end
    end)
  end)
end

hs.hotkey.bind({ "ctrl", "shift" }, "m", function()
  toggleGoogleMeetMute()
end)

logger.i("Google Meet mute module loaded - Hotkeys: Cmd+Alt+M or Ctrl+Shift+M")

