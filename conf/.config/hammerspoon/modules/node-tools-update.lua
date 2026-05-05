NodeToolsUpdate = {}
NodeToolsUpdate.logger = hs.logger.new("node-tools-update", "info")

local repoPath = os.getenv("DOTFILES_DIR") or (os.getenv("HOME") .. "/src/github.com/happy663/dotfiles")
local maxRetries = 5
local retryDelay = 30
local isRunning = false

local function notify(title, text)
  hs.notify
    .new({
      title = title,
      informativeText = text,
      soundName = hs.notify.defaultNotificationSound,
    })
    :send()
end

local function parseResult(stdOut)
  local result = {}
  for line in (stdOut or ""):gmatch("[^\r\n]+") do
    local key, value = line:match("^([A-Z_]+)=(.*)$")
    if key then
      result[key] = value
    end
  end
  return result
end

local function runUpdateScript()
  local command = string.format("cd %q && scripts/update-node-tools.sh", repoPath)
  NodeToolsUpdate.logger.i("Running: " .. command)

  local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
    isRunning = false
    local result = parseResult(stdOut)
    local status = result.RESULT or "failed"
    local logFile = result.LOG_FILE or ""

    NodeToolsUpdate.logger.i("update-node-tools finished: exit=" .. tostring(exitCode) .. ", result=" .. status)
    if stdErr and stdErr ~= "" then
      NodeToolsUpdate.logger.w(stdErr)
    end

    if status == "updated" then
      notify("nodeTools更新完了", "ログ: " .. logFile)
    elseif status == "failed" or exitCode ~= 0 then
      local stage = result.FAILED_STAGE or "unknown"
      local lockfileState = result.LOCKFILE_STATE or "unknown"
      notify("nodeTools更新失敗", "stage: " .. stage .. "\nlockfile: " .. lockfileState .. "\nログ: " .. logFile)
    end
  end, { "-lc", command })

  if not task:start() then
    isRunning = false
    notify("nodeTools更新失敗", "更新スクリプトの起動に失敗しました")
  end
end

local function checkNetworkThenRun(attempt)
  local task = hs.task.new("/usr/bin/curl", function(exitCode)
    if exitCode == 0 then
      NodeToolsUpdate.logger.i("npm registry is reachable")
      runUpdateScript()
      return
    end

    if attempt < maxRetries then
      NodeToolsUpdate.logger.w("npm registry is not reachable; retrying")
      hs.timer.doAfter(retryDelay, function()
        checkNetworkThenRun(attempt + 1)
      end)
      return
    end

    isRunning = false
    notify("nodeTools更新失敗", "npm registryに接続できませんでした")
  end, { "-fsS", "--head", "https://registry.npmjs.org/" })

  if not task:start() then
    isRunning = false
    notify("nodeTools更新失敗", "ネットワーク確認を開始できませんでした")
  end
end

NodeToolsUpdate.watcher = hs.caffeinate.watcher.new(function(eventType)
  if eventType ~= hs.caffeinate.watcher.systemDidWake then
    return
  end

  if isRunning then
    NodeToolsUpdate.logger.i("Update is already running")
    return
  end

  isRunning = true
  checkNetworkThenRun(1)
end)

NodeToolsUpdate.watcher:start()
NodeToolsUpdate.logger.i("nodeTools update watcher started")
