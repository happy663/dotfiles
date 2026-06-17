-- ブラウザの <textarea> にフォーカスした瞬間に ovim Edit Popup を自動起動する。
--
-- 設計のポイント:
-- 1. per-app watcher を使う (systemwide ではない)
--    Edit Popup は Alacritty を別アプリとして起動するため、systemwide 監視だと
--    「テキストエリア → Alacritty にフォーカス」を非テキストエリア遷移として
--    検知してしまい、:wq 後にテキストエリアに戻った瞬間に再発火 → 無限ループになる。
--    per-app watcher だと別アプリ間の遷移は通知が来ないので状態が保たれる。
--
-- 2. 非 AXTextArea にフォーカスが移ったら active 状態をクリアする
--    同じテキストエリアへの即座の再フォーカス (Popup 起動直後など) はスキップしたい
--    が、ユーザーが意図的に別要素 (ボタン/リンク/別の入力欄など) を経由して
--    戻ってきた場合は再発火させたい。非 AXTextArea を「意図的な離脱」のシグナル
--    として扱う。

local hs_application = require("hs.application")
local hs_alert = require("hs.alert")
local hs_osascript = require("hs.osascript")
local hs_logger = hs.logger.new("AutoOvim", "debug")

local OVIM_CLI = "/Applications/ovim.app/Contents/MacOS/ovim"

-- bundleID -> AppleScript で参照するアプリ名
local TARGET_APPS = {
  ["com.vivaldi.Vivaldi"] = "Vivaldi",
  ["com.google.Chrome"] = "Google Chrome",
}

-- ここに列挙した URL パターンに一致するページでのみ自動起動する (allowlist 方式)。
-- denylist だと新しいサイトが増えるたびに誤起動するため、明示的に許可した場所
-- だけで起動する。
--   host:     ホスト名の suffix 一致 ("github.com" は "*.github.com" にもマッチ)
--   patterns: パスに対する Lua パターン。いずれか1つでも一致すれば許可。
-- 現状の要件は「GitHub の issue と PR でだけ起動」。
local ALLOWLIST = {
  {
    host = "github.com",
    patterns = {
      "^/[^/]+/[^/]+/issues/", -- issue 詳細・新規作成
      "^/[^/]+/[^/]+/pull/", -- PR 詳細
    },
  },
}

-- Hammerspoon config reload 時に古い watcher が残ってリークしないよう、
-- 前回ロード時のインスタンスがあれば停止してから再構築する。
if hs._autoOvim and hs._autoOvim.stop then
  hs._autoOvim.stop()
end

local appWatchers = {}
local appWatcher = nil
local activeTextAreaElement = nil
local activeTextAreaKey = nil

local function elementAttribute(element, name)
  local ok, value = pcall(function()
    return element:attributeValue(name)
  end)

  if ok then
    return value
  end

  return nil
end

-- AX要素の参照は同じ要素を指していても呼び出しごとに別オブジェクトになることが
-- あるため、`==` 比較だけでは同一判定に失敗するケースがある。
-- 位置とサイズで fallback キーを作って同一性を判定する。
-- (注: ページがスクロールしたり再レンダされると同一要素でもキーが変わるが、その
-- 場合は再発火するだけで実害はない)
local function elementKey(element)
  local position = elementAttribute(element, "AXPosition")
  local size = elementAttribute(element, "AXSize")

  if not position or not size then
    return nil
  end

  return string.format("%s:%s:%s:%s", tostring(position.x), tostring(position.y), tostring(size.w), tostring(size.h))
end

local function clearActiveTextArea()
  activeTextAreaElement = nil
  activeTextAreaKey = nil
end

local function isActiveTextArea(element)
  local key = elementKey(element)

  if element == activeTextAreaElement or (key and key == activeTextAreaKey) then
    return true
  end

  return false
end

-- 発火判定。挙動の早見表:
--   AXTextArea以外にフォーカス       -> 状態クリア、発火しない
--   active と同じ AXTextArea          -> 発火しない (Popup起動直後の再フォーカス対策)
--   active と異なる AXTextArea        -> 発火、新しい要素を active に更新
--   active が nil の AXTextArea       -> 発火、active に登録
local function shouldTrigger(element)
  if not element then
    return false
  end

  if element:role() ~= "AXTextArea" then
    clearActiveTextArea()
    return false
  end

  if isActiveTextArea(element) then
    hs_logger.d("Skip repeated focus to active textarea")
    return false
  end

  activeTextAreaElement = element
  activeTextAreaKey = elementKey(element)
  return true
end

-- ブラウザのフロントタブのURLを AppleScript で取得する。
-- 取得失敗時は nil を返す。
local function getActiveTabURL(appName)
  local script = string.format('tell application "%s"\nget URL of active tab of front window\nend tell', appName)
  local ok, result = hs_osascript.applescript(script)
  if not ok or type(result) ~= "string" or result == "" then
    return nil
  end
  return result
end

-- URL文字列からホスト名を抽出する。ポート番号は除去する。
-- 抽出できない場合 (about:blank, data: 等) は nil。
local function extractHostname(url)
  local host = url:match("^[%w+%-.]+://([^/]+)")
  if not host then
    return nil
  end
  -- ユーザー情報 (user:pass@) を除去
  host = host:match("@(.+)$") or host
  -- ポートを除去
  host = host:match("^([^:]+)") or host
  return host:lower()
end

-- URL文字列からパス部分 (クエリ・フラグメントを除く) を抽出する。
-- パスがない場合は "/" を返す。
local function extractPath(url)
  local path = url:match("^[%w+%-.]+://[^/]+(/[^?#]*)")
  return path or "/"
end

-- ホスト名が allowlist の host に suffix 一致するかを判定する。
-- "github.com" は "github.com" と "*.github.com" の両方にマッチする。
local function hostMatches(host, allowedHost)
  return host == allowedHost or host:sub(-(#allowedHost + 1)) == "." .. allowedHost
end

-- URL が allowlist のいずれかのエントリ (host + path パターン) に一致するかを判定する。
local function isAllowedUrl(url)
  if not url then
    return false
  end
  local host = extractHostname(url)
  if not host then
    return false
  end
  local path = extractPath(url)
  for _, entry in ipairs(ALLOWLIST) do
    if hostMatches(host, entry.host) then
      for _, pattern in ipairs(entry.patterns) do
        if path:match(pattern) then
          return true
        end
      end
    end
  end
  return false
end

local function triggerOvimEdit(appName)
  -- AppleScript呼び出しは ~100ms かかるが、発火タイミングが稀 (テキストエリア
  -- へのフォーカス時のみ) なので毎回叩いて問題ない。
  local url = getActiveTabURL(appName)
  if not isAllowedUrl(url) then
    hs_logger.d("Skip ovim edit on non-allowed url: " .. tostring(url))
    return
  end

  hs_logger.d("Trigger ovim edit")
  hs.execute(OVIM_CLI .. " edit &", true)
end

local function watchApp(app)
  local bundleID = app:bundleID()
  local appName = TARGET_APPS[bundleID]
  if not appName then
    return
  end

  local pid = app:pid()
  if appWatchers[pid] then
    return
  end

  local watcher = app:newWatcher(function(element, event)
    if event ~= hs.uielement.watcher.focusedElementChanged then
      return
    end

    if shouldTrigger(element) then
      triggerOvimEdit(appName)
    end
  end)

  watcher:start({ hs.uielement.watcher.focusedElementChanged })
  appWatchers[pid] = watcher
  hs_logger.d("Started watcher for " .. bundleID)
end

appWatcher = hs.application.watcher.new(function(_, event, app)
  if event ~= hs.application.watcher.launched and event ~= hs.application.watcher.activated then
    return
  end

  if app then
    watchApp(app)
  end
end)

for bundleID, _ in pairs(TARGET_APPS) do
  local app = hs_application.get(bundleID)
  if app then
    watchApp(app)
  end
end

appWatcher:start()
hs_alert.show("Auto Ovim Loaded")

hs._autoOvim = {
  stop = function()
    if appWatcher then
      appWatcher:stop()
    end

    for _, watcher in pairs(appWatchers) do
      watcher:stop()
    end

    appWatchers = {}
    clearActiveTextArea()
  end,
}
