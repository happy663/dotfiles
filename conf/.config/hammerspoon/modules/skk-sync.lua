-- SKK辞書自動同期モジュール
logger = hs.logger.new("skk-sync", "info")

-- デバッグ用：モジュール読み込み時にアラートを表示
hs.alert.show("SKK-syncモジュールを読み込みました")

-- SKK辞書のリポジトリパス
local skkRepoPath = os.getenv("HOME") .. "/src/github.com/ppha3260-web/my-skk-dict"
logger.i("SKK dictionary repository path: " .. skkRepoPath)

-- Git操作用のヘルパー関数
local function executeGitCommand(args, callback)
  local allArgs = { "-C", skkRepoPath }
  for _, arg in ipairs(args) do
    table.insert(allArgs, arg)
  end

  local task = hs.task.new("/usr/bin/git", callback, allArgs)
  task:start()
  return task
end

-- 変更があるかチェック
local function hasChanges(callback)
  executeGitCommand({ "status", "--porcelain" }, function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      local hasModifications = stdOut and stdOut ~= ""
      callback(hasModifications)
    else
      logger.e("Failed to check git status: " .. (stdErr or ""))
      callback(false)
    end
  end)
end

-- コミットとプッシュを実行
local function commitAndPush()
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local commitMessage = "Auto-sync SKK dictionary at " .. timestamp

  -- まず add を実行
  executeGitCommand({ "add", "userDict", "userCompletionRankFile.json" }, function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      logger.e("Failed to add files: " .. (stdErr or ""))
      hs.notify
        .new({
          title = "SKK辞書同期エラー",
          informativeText = "ファイルの追加に失敗しました",
          soundName = hs.notify.defaultNotificationSound,
        })
        :send()
      return
    end

    -- 次に commit を実行
    executeGitCommand({ "commit", "-m", commitMessage }, function(exitCode, stdOut, stdErr)
      if exitCode ~= 0 then
        logger.e("Failed to commit: " .. (stdErr or ""))
        hs.notify
          .new({
            title = "SKK辞書同期エラー",
            informativeText = "コミットに失敗しました",
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()
        return
      end

      logger.i("Commit successful, now pushing...")

      -- 最後に push を実行
      executeGitCommand({ "push" }, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          hs.notify
            .new({
              title = "SKK辞書同期完了",
              informativeText = "辞書の同期が完了しました",
              soundName = hs.notify.defaultNotificationSound,
            })
            :send()
          logger.i("Push completed successfully")
        else
          hs.notify
            .new({
              title = "SKK辞書同期警告",
              informativeText = "プッシュに失敗しました（次回起動時に再試行）",
              soundName = hs.notify.defaultNotificationSound,
            })
            :send()
          logger.w("Push failed (will retry on next wake): " .. (stdErr or ""))
        end
      end)
    end)
  end)
end

-- Pull を実行
local function pullChanges()
  executeGitCommand({ "pull", "--rebase" }, function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.notify
        .new({
          title = "SKK辞書同期",
          informativeText = "最新の辞書を取得しました",
          soundName = hs.notify.defaultNotificationSound,
        })
        :send()
      logger.i("Pull completed successfully")
    else
      if stdErr and stdErr:match("conflict") then
        hs.notify
          .new({
            title = "SKK辞書同期エラー",
            informativeText = "競合が発生しました。手動で解決してください",
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()
        logger.e("Merge conflict detected: " .. stdErr)
      else
        hs.notify
          .new({
            title = "SKK辞書同期エラー",
            informativeText = "同期に失敗しました: " .. (stdErr or ""),
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()
        logger.e("Pull failed: " .. (stdErr or ""))
      end
    end
  end)
end

-- スリープ/復帰イベントの監視
watcher = hs.caffeinate.watcher.new(function(eventType)
  logger.i("Caffeinate event received: " .. tostring(eventType))

  if eventType == hs.caffeinate.watcher.systemWillSleep then
    logger.i("System will sleep, checking for changes...")
    hs.alert.show("スリープ前: SKK辞書の変更をチェック中...")

    hasChanges(function(hasModifications)
      if hasModifications then
        logger.i("Changes detected, committing and pushing...")
        hs.alert.show("変更を検出: コミット＆プッシュ中...")
        commitAndPush()
      else
        logger.i("No changes detected")
        hs.alert.show("変更なし: スキップ")
      end
    end)
  elseif eventType == hs.caffeinate.watcher.systemDidWake then
    logger.i("System woke up, pulling latest changes...")
    hs.alert.show("システム復帰: 最新の辞書を取得中...")

    -- まず未プッシュのコミットがあるかチェック
    executeGitCommand({ "status", "-sb" }, function(exitCode, stdOut, stdErr)
      if stdOut and stdOut:match("ahead") then
        logger.i("Unpushed commits detected, pushing first...")
        executeGitCommand({ "push" }, function(exitCode, stdOut, stdErr)
          if exitCode == 0 then
            logger.i("Push completed, now pulling...")
          end
          pullChanges()
        end)
      else
        pullChanges()
      end
    end)
  end
end)

watcher:start()
logger.i("SKK dictionary sync watcher started")

-- 手動同期用のホットキー（Cmd+Ctrl+S）
hs.hotkey.bind({ "cmd", "ctrl" }, "S", function()
  hs.alert.show("SKK辞書の手動同期を開始...")
  hasChanges(function(hasModifications)
    if hasModifications then
      commitAndPush()
    else
      hs.alert.show("変更なし")
    end
  end)
end)
