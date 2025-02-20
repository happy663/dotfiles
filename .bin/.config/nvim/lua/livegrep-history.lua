local M = {}
local history_file = vim.fn.stdpath("data") .. "/telescope_livegrep_history.json"
local history = {}
local history_index = 1

-- 履歴をファイルから読み込む
local function load_history()
  local file = io.open(history_file, "r")  
  if file then
    local content = file:read("*all")
    file:close()
    if content and content ~= "" then
      history = vim.json.decode(content) or {}
    end
  end
end

-- 履歴をファイルに保存
local function save_history()
  local file = io.open(history_file, "w")
  if file then
    file:write(vim.json.encode(history))
    file:close()
  end
end

-- 履歴に追加
local function add_to_history(query)
  if query and query ~= "" then
    -- 重複を避けるため、既存の同じクエリを削除
    for i = #history, 1, -1 do
      if history[i] == query then
        table.remove(history, i)
        break
      end
    end

    -- 先頭に追加
    table.insert(history, 1, query)

    -- 最大100件まで保持
    if #history > 100 then
      table.remove(history)
    end

    save_history()
  end
end

-- カスタマイズされたlive_grep
function M.live_grep_with_history()
  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- 初回実行時に履歴を読み込む
  if #history == 0 then
    load_history()
  end

  builtin.live_grep({
    default_text = history[1] or "",
    attach_mappings = function(prompt_bufnr, map)
      -- Up/Downキーで履歴を辿る
      map("i", "<Up>", function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local prompt = picker:_get_prompt()

        if history_index < #history then
          history_index = history_index + 1
          picker:set_prompt(history[history_index])
        end
      end)

      map("i", "<Down>", function()
        local picker = action_state.get_current_picker(prompt_bufnr)

        if history_index > 1 then
          history_index = history_index - 1
          picker:set_prompt(history[history_index])
        elseif history_index == 1 then
          history_index = 0
          picker:set_prompt("")
        end
      end)

      -- Enterキーで検索実行時に履歴に追加
      map("i", "<CR>", function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local query = picker:_get_prompt()
        add_to_history(query)
        history_index = 0
        actions.select_default(prompt_bufnr)
      end)

      return true
    end,
  })
end

-- キーマッピングの設定例
vim.keymap.set("n", "<leader>gg", M.live_grep_with_history, { desc = "Live Grep with History" })

return M
