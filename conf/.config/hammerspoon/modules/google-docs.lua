local hs_application = require("hs.application")
local hs_osascript = require("hs.osascript")
local hs_eventtap = require("hs.eventtap")
local hs_hotkey = require("hs.hotkey")
local hs_alert = require("hs.alert")
local hs_timer = require("hs.timer")
local hs_logger = hs.logger.new("GoogleDocsEscRemap", "debug")

-- Google Docsのモーダルキーマップを作成
local googleDocsKeyMap = hs.hotkey.modal.new()

-- 設定変数
local targetUrlPrefix = "https://docs.google.com/document"

-- 現在アクティブなブラウザのURLを取得する関数
local function getActiveBrowserUrl()
  local frontmostApp = hs_application.frontmostApplication()

  if not frontmostApp or frontmostApp:bundleID() ~= "com.google.Chrome" then
  end

  local script = 'tell application "Google Chrome" to return URL of active tab of front window'
  local success, result, rawOutput = hs_osascript.applescript(script)

  if success and type(result) == "string" then
    return result
  else
    hs_logger.d("URLを取得できませんでした: " .. hs.inspect(rawOutput))
    return nil
  end
end

-- アプリケーションがGoogleドキュメントかどうかを確認して、キーマップを有効/無効にする
local function chooseKeyMap()
  local frontmostApp = hs_application.frontmostApplication()

  if frontmostApp and frontmostApp:bundleID() == "com.google.Chrome" then
    local currentUrl = getActiveBrowserUrl()

    if currentUrl and currentUrl:sub(1, #targetUrlPrefix) == targetUrlPrefix then
      hs_logger.d("Google Docsでキーマップを有効化")
      googleDocsKeyMap:enter()
    else
      hs_logger.d("Google Docs以外でキーマップを無効化")
      googleDocsKeyMap:exit()
    end
  else
    hs_logger.d("Chrome以外のアプリでキーマップを無効化")
    googleDocsKeyMap:exit()
  end
end

local isProcessRunning = false

-- ESCキーが押されたときの処理関数
local function handleEscKey()
  if isProcessRunning then
    hs_logger.d("ESCキーが押されましたが、処理中です")
    return
  end

  isProcessRunning = true
  hs_eventtap.keyStroke({}, "l")
  hs_logger.d("Lキーを押しました")
  -- ESCキーを明示的に処理
  hs_eventtap.event.newKeyEvent({}, "escape", true):post()
  hs_eventtap.event.newKeyEvent({}, "escape", false):post()

  hs_timer.doAfter(0.1, function()
    isProcessRunning = false
  end)
end

-- ESCキーをバインド
googleDocsKeyMap:bind({}, "escape", handleEscKey)

-- アプリケーションウォッチャーの定義
local function appWatcherFunction(appName, eventType, appObject)
  if eventType == hs.application.watcher.activated then
    chooseKeyMap()
  end
end

-- アプリケーションウォッチャーの起動
local appWatcher = hs.application.watcher.new(appWatcherFunction)
appWatcher:start()

-- URLの変更を監視するタイマー（Chromeが前面にある場合のみ、URLの変更を検出）
local function checkUrlTimer()
  local frontmostApp = hs_application.frontmostApplication()
  if frontmostApp and frontmostApp:bundleID() == "com.google.Chrome" then
    chooseKeyMap()
  end
end

local urlCheckTimer = hs_timer.new(2, checkUrlTimer)
urlCheckTimer:start()

-- スクリプトがロードされたことを通知
hs_alert.show("Google Docs ESC Remap Loaded (Chrome Only)")

-- 初期状態をセット
chooseKeyMap()
