-- Hammerspoon module for opening GitHub issues in Neovim/Octo

local M = {}

-- ホットキー設定: Cmd+Shift+O
hs.hotkey.bind({ "cmd", "shift" }, "O", function()
  -- 現在アクティブなアプリケーションを取得
  local app = hs.application.frontmostApplication()
  local appName = app:name()

  local url = nil

  -- Chromeの場合
  if appName == "Google Chrome" then
    local script = [[
            tell application "Google Chrome"
                get URL of active tab of front window
            end tell
        ]]
    local ok, result = hs.osascript.applescript(script)
    if ok then
      url = result
    end
    -- Safariの場合
  elseif appName == "Safari" then
    local script = [[
            tell application "Safari"
                get URL of current tab of front window
            end tell
        ]]
    local ok, result = hs.osascript.applescript(script)
    if ok then
      url = result
    end
  end

  -- GitHub issueのURLかチェック
  if url and (url:match("github.com/.+/.+/issues/%d+") or url:match("github.com/.+/.+/pull/%d+")) then
    print("GitHub URL detected: " .. url)

    -- WeztermのOcto windowにフォーカスを移動してURLを渡す
    -- 一旦URLをクリップボードにコピー
    hs.pasteboard.setContents(url)

    -- Weztermにフォーカスを移動
    local wezterm = hs.application.get("WezTerm")
    if wezterm then
      wezterm:activate()

      -- 少し待ってから処理を続ける
      hs.timer.doAfter(0.5, function()
        -- TODO: 特定のwindowを識別してフォーカスする処理を追加
        hs.alert.show("URL copied: " .. url)
      end)
    else
      hs.alert.show("WezTerm not running. Please start WezTerm first.")
    end
  else
    hs.alert.show("Not a GitHub issue/PR URL")
  end
end)

print("Octo module loaded: Use Cmd+Shift+O on a GitHub issue page.")

return M
