-- parse_task_name_improved.lua
-- 改良版のparse_task_name関数（モジュールとして提供）

local M = {}

M.parse_task_name = function(line)
  local task_name = nil

  -- org表示モードのパターン（大文字小文字両対応）
  local display_mode_pattern = line:match("^%s*(%w+):")
  if display_mode_pattern then
    local mode = display_mode_pattern:lower()
    -- todo, done, doing, waiting, cancelledなどに対応
    if mode == "todo" or mode == "done" or mode == "doing" or mode == "waiting" or mode == "cancelled" then
      -- 優先度ありのパターン（状態キーワードありとなし両方対応）
      task_name = line:match(":%s*%w+%s+%[#[A-D]%]%s+(.-)%s*$")
      if not task_name then
        -- 優先度のみのパターン（TODO: [#C] タスク名）
        task_name = line:match(":%s*%[#[A-D]%]%s+(.-)%s*$")
      end
      if not task_name then
        -- 優先度なしのパターン
        task_name = line:match(":%s*%w+%s+(.-)%s*$")
      end
      if not task_name then
        -- 状態キーワードなしのパターン（TODO: タスク名）
        task_name = line:match(":%s+(.-)%s*$")
      end

      -- チェックボックスを含む場合の処理
      if task_name and task_name:match("%[%d*/%d*%]") then
        task_name = task_name:gsub("%s*%[%d*/%d*%]%s*", " ")
      end
    end
  else
    -- 通常のorg形式
    -- すべてのTODO状態に対応（TODO, DONE, DOING, WAITING, CANCELLED）
    local status_pattern = "^(%*+)%s+(%w+)%s+"
    local level, status = line:match(status_pattern)

    if level and status then
      local valid_statuses = {
        TODO = true,
        DONE = true,
        DOING = true,
        WAITING = true,
        CANCELLED = true,
      }

      if valid_statuses[status] then
        -- 優先度ありのパターン
        task_name = line:match("%*+%s+%w+%s+%[#[A-D]%]%s+(.-)%s*:")
        if not task_name then
          task_name = line:match("%*+%s+%w+%s+%[#[A-D]%]%s+(.-)%s*$")
        end

        -- 優先度なしのパターン
        if not task_name then
          task_name = line:match("%*+%s+%w+%s+(.-)%s*:")
          if not task_name then
            task_name = line:match("%*+%s+%w+%s+(.-)%s*$")
          end
        end

        -- チェックボックスを除去
        if task_name then
          -- [/] や [1/3] のようなチェックボックスを除去
          task_name = task_name:gsub("%s*%[%d*/%d*%]%s*", " ")
          -- 前後の空白を除去
          task_name = task_name:gsub("^%s+", ""):gsub("%s+$", "")
        end
      end
    end
  end

  if not task_name then
    return nil
  end

  -- タスク名のクリーンアップ
  -- タグ（:tag:形式）を除去
  task_name = task_name:gsub(":%w+:", "")
  -- 前後の空白を除去
  task_name = task_name:gsub("^%s+", ""):gsub("%s+$", "")

  -- search_nameの生成（改良版）
  local search_name = task_name

  -- 日本語を含む場合の処理を改善
  -- アルファベット、数字、ハイフン、アンダースコアは保持
  -- それ以外の文字（日本語含む）はそのまま保持して、後でハイフンに変換

  -- まず、特殊記号を除去（ただし日本語は保持）
  search_name = search_name:gsub("[%(%)%[%]{}!@#$%%^&*+=|\\/<>,.?:;\"'`~]", " ")

  -- 連続する空白を単一のハイフンに変換
  search_name = search_name:gsub("%s+", "-")

  -- 先頭と末尾のハイフンを除去
  search_name = search_name:gsub("^%-+", ""):gsub("%-+$", "")

  -- 小文字に変換（日本語はそのまま）
  search_name = search_name:lower()

  -- 20文字に制限
  -- 日本語を考慮して、UTF-8文字列として適切に処理
  if #search_name > 60 then -- バイト数で制限（日本語1文字=3バイト程度）
    search_name = search_name:sub(1, 60)
    -- 最後の文字が不完全な場合の処理
    search_name = search_name:gsub("%-$", "")
  end

  return task_name, search_name
end

-- LazyNvimが誤ってプラグインとして認識しないように、モジュールとして返す
return M
