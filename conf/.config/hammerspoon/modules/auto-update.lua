-- node-pkgs自動更新モジュール
-- スリープ復帰時に1日1回 `make auto-update-node-pkgs` を実行する。
-- スクリプト側で home-manager 関連ファイルの dirty チェックと
-- ネットワーク疎通確認を行う。
AutoUpdate = {}
AutoUpdate.logger = hs.logger.new("auto-update", "info")

local home = os.getenv("HOME")
local dotfilesPath = home .. "/src/github.com/happy663/dotfiles"
local scriptPath = dotfilesPath .. "/scripts/auto-update-node-pkgs.sh"
local stateDir = home .. "/.cache/hammerspoon"
local stateFile = stateDir .. "/auto-update-node-pkgs-last-run"

-- スクリプトの終了コード（scripts/auto-update-node-pkgs.sh と一致させる）
local EXIT_SKIP_DIRTY = 10
local EXIT_SKIP_NETWORK = 11

-- 最終実行日（YYYY-MM-DD）を読み込む。なければnil。
local function getLastRunDate()
  local f = io.open(stateFile, "r")
  if not f then
    return nil
  end
  local date = f:read("*l")
  f:close()
  return date
end

-- 最終実行日を保存
local function saveLastRunDate(date)
  hs.fs.mkdir(stateDir)
  local f = io.open(stateFile, "w")
  if f then
    f:write(date)
    f:close()
  end
end

local function today()
  return os.date("%Y-%m-%d")
end

local function alreadyRanToday()
  return getLastRunDate() == today()
end

-- 更新を実行
local function runUpdate()
  AutoUpdate.logger.i("Starting auto-update-node-pkgs ...")
  hs.notify
    .new({
      title = "node-pkgs自動更新",
      informativeText = "更新を開始します",
    })
    :send()

  -- 直接スクリプトを呼ぶ。makeを経由するとレシピ失敗時に終了コードが
  -- 一律2に丸められるため、SKIPと実失敗の区別がつかなくなる。
  local task = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
    AutoUpdate.logger.i("script exit=" .. tostring(exitCode))
    if stdOut and stdOut ~= "" then
      AutoUpdate.logger.i("stdout: " .. stdOut)
    end
    if stdErr and stdErr ~= "" then
      AutoUpdate.logger.w("stderr: " .. stdErr)
    end

    if exitCode == 0 then
      saveLastRunDate(today())
      hs.notify
        .new({
          title = "node-pkgs自動更新完了",
          informativeText = "更新が完了しました",
        })
        :send()
    elseif exitCode == EXIT_SKIP_DIRTY then
      -- home-manager評価ファイルがdirtyでスキップ。今日は再試行しない。
      saveLastRunDate(today())
      AutoUpdate.logger.i("Skipped: watched files dirty")
      hs.notify
        .new({
          title = "node-pkgs自動更新スキップ",
          informativeText = "home-manager関連ファイルに変更があるため今日はスキップ",
        })
        :send()
    elseif exitCode == EXIT_SKIP_NETWORK then
      -- ネットワーク未接続。state fileは更新しないので次回起動時に再試行。
      AutoUpdate.logger.i("Skipped: no network")
    else
      hs.notify
        .new({
          title = "node-pkgs自動更新失敗",
          informativeText = "exit " .. tostring(exitCode) .. " (詳細はlog参照)",
          soundName = hs.notify.defaultNotificationSound,
        })
        :send()
    end
  end, {})

  -- nix/npm/git/curl が解決できるPATHと、home-manager等が参照する
  -- HOME/USER/LOGNAME/LANG をセットする。setEnvironmentは環境を完全に
  -- 置き換えるので、必要なものは明示的に渡す必要がある。
  local user = os.getenv("USER") or ""
  task:setEnvironment({
    HOME = home,
    USER = user,
    LOGNAME = os.getenv("LOGNAME") or user,
    LANG = os.getenv("LANG") or "en_US.UTF-8",
    PATH = (os.getenv("PATH") or "")
      .. ":/run/current-system/sw/bin:"
      .. home
      .. "/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
  })
  task:start()
end

local function checkAndRun(reason)
  AutoUpdate.logger.i("checkAndRun triggered: " .. (reason or "unknown"))
  if alreadyRanToday() then
    AutoUpdate.logger.i("Already ran today (" .. today() .. "), skipping")
    hs.notify
      .new({
        title = "node-pkgs自動更新スキップ",
        informativeText = "本日 (" .. today() .. ") は実行済み",
      })
      :send()
    return
  end
  runUpdate()
end

-- スリープ復帰イベントの監視
AutoUpdate.watcher = hs.caffeinate.watcher.new(function(eventType)
  if eventType == hs.caffeinate.watcher.systemDidWake then
    AutoUpdate.logger.i("systemDidWake")
    -- 復帰直後はネットワークが安定しないので少し待つ
    hs.timer.doAfter(15, function()
      checkAndRun("systemDidWake")
    end)
  end
end)
AutoUpdate.watcher:start()

-- Hammerspoon起動・reload時にも1回だけチェック
hs.timer.doAfter(10, function()
  checkAndRun("startup")
end)

-- 手動実行用ホットキー（Cmd+Ctrl+U）
hs.hotkey.bind({ "cmd", "ctrl" }, "U", function()
  hs.alert.show("node-pkgs自動更新を手動実行...")
  -- 手動実行時は当日チェックを無視
  runUpdate()
end)

AutoUpdate.logger.i("Auto-update watcher started")
