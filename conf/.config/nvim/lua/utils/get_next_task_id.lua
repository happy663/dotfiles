-- get_next_task_id.lua
-- タスクID生成関数をモジュールとして提供

local M = {}

-- ID生成用の関数
M.get_next_task_id = function(logs_dir)
  -- ディレクトリパスが指定されていない場合はデフォルトを使用
  logs_dir = logs_dir or vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/tasks/")

  local max_id = 0
  local files = vim.fn.glob(logs_dir .. "task-*.org", false, true)

  for _, file in ipairs(files) do
    local num = tonumber(file:match("task%-(%d+)"))
    if num and num > max_id then
      max_id = num
    end
  end

  return string.format("task-%03d", max_id + 1)
end

return M
