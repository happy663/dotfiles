-- org-memo自動同期モジュール
OrgSync = {}
OrgSync.logger = hs.logger.new("org-sync", "info")

-- デバッグ用：モジュール読み込み時にアラートを表示
hs.alert.show("org-syncモジュールを読み込みました")

-- スリープ復帰時のイベント監視
OrgSync.watcher = hs.caffeinate.watcher.new(function(eventType)
  OrgSync.logger.i("Caffeinate event received: " .. tostring(eventType))

  if eventType == hs.caffeinate.watcher.systemDidWake then
    OrgSync.logger.i("System woke up, syncing org-memo...")
    hs.alert.show("システム復帰を検知、同期を開始します...")

    -- 同期対象のディレクトリパスを明示的に定義
    local repoPath = os.getenv("HOME") .. "/src/github.com/happy663/org-memo"
    OrgSync.logger.i("Repository path: " .. repoPath)
    -- 非同期でgit pull実行
    local task = hs.task.new("/usr/bin/git", function(exitCode, stdOut, stdErr)
      if exitCode == 0 then
        hs.notify
          .new({
            title = "Org-memo同期",
            informativeText = "同期が完了しました",
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()
        OrgSync.logger.i("Sync completed successfully")
      else
        hs.notify
          .new({
            title = "Org-memo同期エラー",
            informativeText = "同期に失敗しました: " .. (stdErr or ""),
            soundName = hs.notify.defaultNotificationSound,
          })
          :send()

        OrgSync.logger.e("Sync failed: " .. (stdErr or ""))
      end
    end, { "-C", os.getenv("HOME") .. "/src/github.com/happy663/org-memo", "pull", "--rebase" })

    -- タスクを開始
    task:start()
  end
end)

OrgSync.watcher:start()
OrgSync.logger.i("Org-memo sync watcher started")
