-- Dotfiles自動同期モジュール（push/pullのみ、自動コミットはしない）
DotfilesSync = {}
DotfilesSync.logger = hs.logger.new("dotfiles-sync", "info")

-- デバッグ用：モジュール読み込み時にアラートを表示
hs.alert.show("Dotfiles-syncモジュールを読み込みました")

-- Dotfilesのリポジトリパス
local dotfilesRepoPath = os.getenv("HOME") .. "/src/github.com/happy663/dotfiles"
DotfilesSync.logger.i("Dotfiles repository path: " .. dotfilesRepoPath)

-- Git操作用のヘルパー関数
local function executeGitCommand(args, callback)
  local allArgs = { "-C", dotfilesRepoPath }
  for _, arg in ipairs(args) do
    table.insert(allArgs, arg)
  end

  local task = hs.task.new("/usr/bin/git", callback, allArgs)
  task:start()
  return task
end

-- 未pushコミットがあるかチェック
local function hasUnpushedCommits(callback)
  executeGitCommand({ "status", "-sb" }, function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      callback(stdOut and stdOut:match("ahead") ~= nil)
    else
      DotfilesSync.logger.e("Failed to check git status: " .. (stdErr or ""))
      callback(false)
    end
  end)
end

-- Push を実行
local function pushChanges()
  executeGitCommand({ "push" }, function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.notify
        .new({
          title = "Dotfiles同期完了",
          informativeText = "dotfilesをプッシュしました",
          soundName = hs.notify.defaultNotificationSound,
        })
        :send()
      DotfilesSync.logger.i("Push completed successfully")
    else
      hs.notify
        .new({
          title = "Dotfiles同期警告",
          informativeText = "プッシュに失敗しました（次回起動時に再試行）",
          soundName = hs.notify.defaultNotificationSound,
        })
        :send()
      DotfilesSync.logger.w("Push failed (will retry on next wake): " .. (stdErr or ""))
    end
  end)
end

-- Pull を実行
local function pullChanges()
  executeGitCommand({ "pull", "--ff-only" }, function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.notify
        .new({
          title = "Dotfiles同期",
          informativeText = "最新のdotfilesを取得しました",
          soundName = hs.notify.defaultNotificationSound,
        })
        :send()
      DotfilesSync.logger.i("Pull completed successfully")
    else
      if stdErr and stdErr:match("conflict") then
        hs.notify
          .new({
            title = "Dotfiles同期エラー",
            informativeText = "競合が発生しました。手動で解決してください",
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()
        DotfilesSync.logger.e("Merge conflict detected: " .. stdErr)
      else
        hs.notify
          .new({
            title = "Dotfiles同期エラー",
            informativeText = "同期に失敗しました: " .. (stdErr or ""),
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()
        DotfilesSync.logger.e("Pull failed: " .. (stdErr or ""))
      end
    end
  end)
end

-- スリープ/復帰イベントの監視
DotfilesSync.watcher = hs.caffeinate.watcher.new(function(eventType)
  DotfilesSync.logger.i("Caffeinate event received: " .. tostring(eventType))

  if eventType == hs.caffeinate.watcher.systemWillSleep then
    DotfilesSync.logger.i("System will sleep, checking for unpushed commits...")
    hs.alert.show("スリープ前: Dotfilesの未pushコミットをチェック中...")

    hasUnpushedCommits(function(hasUnpushed)
      if hasUnpushed then
        DotfilesSync.logger.i("Unpushed commits detected, pushing...")
        hs.alert.show("未pushコミットを検出: プッシュ中...")
        pushChanges()
      else
        DotfilesSync.logger.i("No unpushed commits")
        hs.alert.show("未pushコミットなし: スキップ")
      end
    end)
  elseif eventType == hs.caffeinate.watcher.systemDidWake then
    DotfilesSync.logger.i("System woke up, pulling latest changes...")
    hs.alert.show("システム復帰: 最新のdotfilesを取得中...")

    -- まず未プッシュのコミットがあるかチェック
    hasUnpushedCommits(function(hasUnpushed)
      if hasUnpushed then
        DotfilesSync.logger.i("Unpushed commits detected, pushing first...")
        executeGitCommand({ "push" }, function(exitCode, stdOut, stdErr)
          if exitCode == 0 then
            DotfilesSync.logger.i("Push completed, now pulling...")
          end
          pullChanges()
        end)
      else
        pullChanges()
      end
    end)
  end
end)

DotfilesSync.watcher:start()
DotfilesSync.logger.i("Dotfiles sync watcher started")

-- 手動同期用のホットキー（Cmd+Ctrl+D）
hs.hotkey.bind({ "cmd", "ctrl" }, "D", function()
  hs.alert.show("Dotfilesの手動同期を開始...")
  hasUnpushedCommits(function(hasUnpushed)
    if hasUnpushed then
      pushChanges()
    else
      hs.alert.show("未pushコミットなし")
    end
  end)
end)
