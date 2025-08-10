-- Discord ミュート切り替えモジュール
local logger = hs.logger.new("discord-mute", "info")

-- モジュール読み込み時の通知
hs.alert.show("Discord ミュートモジュールを読み込みました")

-- ミュート状態を追跡する変数（初期状態はミュート解除）
local isMuted = false

-- Discord ミュート切り替え関数
local function toggleDiscordMute()
  -- Discord アプリケーションを取得
  local discord = hs.application.find("Discord")

  if not discord then
    hs.alert.show("⚠️ Discord が起動していません")
    logger.w("Discord application not found")
    return
  end

  -- 現在フォーカスされているアプリを保存
  local currentApp = hs.application.frontmostApplication()

  -- Discord にフォーカスを移動（バックグラウンドでも動作させるため）
  discord:activate()

  -- 少し待機してからキーイベントを送信
  hs.timer.doAfter(0.05, function()
    -- Cmd+Shift+M を送信（Discord のミュートトグルショートカット）
    hs.eventtap.keyStroke({ "cmd", "shift" }, "m", 0, discord)
    
    -- ミュート状態を切り替え
    isMuted = not isMuted

    -- 元のアプリケーションにフォーカスを戻す
    hs.timer.doAfter(0.05, function()
      if currentApp and currentApp:isRunning() then
        currentApp:activate()
      end

      -- ミュート状態に応じた視覚的フィードバック
      if isMuted then
        hs.alert.show("🔇 Discord ミュート: ON", nil, nil, 1.5)
        logger.i("Discord muted")
      else
        hs.alert.show("🎤 Discord ミュート: OFF", nil, nil, 1.5)
        logger.i("Discord unmuted")
      end
    end)
  end)
end

-- グローバルホットキーの設定
-- Cmd+Alt+M でミュート切り替え
hs.hotkey.bind({ "cmd", "alt" }, "m", function()
  toggleDiscordMute()
end)

-- 代替ホットキー: Ctrl+Shift+M でも動作するように設定
hs.hotkey.bind({ "ctrl", "shift" }, "m", function()
  toggleDiscordMute()
end)

logger.i("Discord mute module loaded - Hotkeys: Cmd+Alt+M or Ctrl+Shift+M")
