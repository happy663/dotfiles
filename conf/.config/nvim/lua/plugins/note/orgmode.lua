return {
  {
    "nvim-orgmode/orgmode",
    -- Pin to avoid e448c72 which introduces E36: Not enough room on TODO toggle
    -- See: https://github.com/nvim-orgmode/orgmode/issues/1109
    commit = "dc9864f",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      -- Load treesitter grammar for org
      -- require("orgmode").setup_ts_grammar()
      -- Setup orgmode
      require("orgmode").setup({
        win_split_mode = "vertical",
        org_agenda_files = {
          "~/src/github.com/happy663/org-memo/org/todo.org",
          "~/src/github.com/happy663/org-memo/org/calendar-beorg.org",
          "~/src/github.com/happy663/org-memo/org/logs/quick.org",
          "~/src/github.com/happy663/org-memo/org/weekly-notes.org",
        },
        org_default_notes_file = "~/src/github.com/happy663/org-memo/org/todo.org", -- デフォルトのタスクファイル
        org_capture_templates = {
          t = {
            description = "タスク追加",
            template = "* TODO [#D] %? [/] :%^{タグ|work|dev|private}:",
            target = "~/src/github.com/happy663/org-memo/org/todo.org",
            -- headline = "%^{カテゴリ|Work|Dev|Private}", -- nvim-orgmodeではプロンプト構文は使えない
          },
          q = {
            description = "クイックメモ",
            template = "* [%<%Y-%m-%d %a %H:%M>] %?\n",
            target = "~/src/github.com/happy663/org-memo/org/logs/quick.org",
          },
          l = {
            description = "作業ログ付きタスク",
            template = [[* TODO [#D] %? [/] :%^{タグ|work|dev|private}:
   :LOGBOOK:
   - Note taken on [%U] \\
     開始: 
  :END:]],
            target = "~/src/github.com/happy663/org-memo/org/todo.org",
            -- headline = "%^{カテゴリ|Work|Dev|Private}", -- nvim-orgmodeではプロンプト構文は使えない
          },
          n = {
            description = "週次注意事項",
            template = "* %? :weekly:",
            target = "~/src/github.com/happy663/org-memo/org/weekly-notes.org",
          },
        },
        -- タスク状態（作業ログ対応）
        -- org_todo_keywords = { "TODO(t)", "DOING(s!)", "WAITING(w@)", "|", "DONE(d!)", "CANCELLED(c@)" }, -- ! = タイムスタンプ記録, @ = ノート記録
        org_todo_keywords = { "TODO", "DOING", "WAITING", "|", "DONE" }, -- タスクの状態
        org_priority_highest = "A", -- 最高優先度
        org_priority_default = "D", -- デフォルト優先度
        org_priority_lowest = "D", -- 最低優先度
        -- フォールディング（折りたたみ）の設定
        org_startup_folded = "showeverything", -- フォールディングを完全に無効にする
        -- ログ機能の設定
        org_log_into_drawer = "LOGBOOK", -- ログをLOGBOOKドローワに収納
        org_log_done = "time", -- DONE時にタイムスタンプを追加
        org_clock_into_drawer = "CLOCKING", -- クロック情報を専用ドローワに
        -- カスタムアジェンダコマンド
        org_agenda_custom_commands = {
          -- wキー: 仕事のタスクだけ
          w = {
            description = "Combined view", -- Description shown in the prompt for the shortcut
            types = {
              {
                type = "tags",
                match = "weekly",
                org_agenda_overriding_header = "📌 今週気をつけたいこと",
              },
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = '+PRIORITY="A"|work+PRIORITY="B"|private+PRIORITY="B"', -- 高優先度のタスク
                org_agenda_overriding_header = "High priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = 'work+PRIORITY="C"', -- 高優先度のタスク
                org_agenda_overriding_header = "Middle priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "My daily agenda",
                org_agenda_span = "day", -- can be any value as org_agenda_span
              },
              {
                type = "tags_todo",
                match = 'work+PRIORITY="D"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_overriding_header = "Low priority work tasks",
              },
              {
                type = "tags_todo",
                match = 'work+TODO="DONE"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_overriding_header = "DONE work tasks",
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "Whole week overview",
                org_agenda_span = "week", -- 'week' is default, so it's not necessary here, just an example
                org_agenda_start_on_weekday = 1, -- Start on Monday
                org_agenda_remove_tags = true, -- Do not show tags only for this view
              },
            },
          },
          p = {
            description = "プライベートのタスク",
            types = {
              {
                type = "tags",
                match = "weekly",
                org_agenda_overriding_header = "📌 今週気をつけたいこと",
              },
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = 'private+PRIORITY="A"|private+PRIORITY="B"|private+PRIORITY="C"', -- 高優先度のタスク
                org_agenda_overriding_header = "High priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "tags_todo",
                org_agenda_overriding_header = "My private todos",
                match = "+private",
                -- match = '+PRIORITY="B"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                order = 10,
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "Whole week overview",
                org_agenda_span = "week", -- 'week' is default, so it's not necessary here, just an example
                org_agenda_start_on_weekday = 1, -- Start on Monday
                org_agenda_remove_tags = true, -- Do not show tags only for this view
              },
            },
          },
          d = {
            description = "開発のタスク",
            types = {
              {
                type = "tags",
                match = "weekly",
                org_agenda_overriding_header = "📌 今週気をつけたいこと",
              },
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = 'dev+PRIORITY="A"|dev+PRIORITY="B"', -- 高優先度のタスク
                org_agenda_overriding_header = "High priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "tags_todo",
                org_agenda_overriding_header = "My dev todos",
                match = "+dev",
                -- match = '+PRIORITY="B"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                order = 10,
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "Whole week overview",
                org_agenda_span = "week", -- 'week' is default, so it's not necessary here, just an example
                org_agenda_start_on_weekday = 1, -- Start on Monday
                org_agenda_remove_tags = true, -- Do not show tags only for this view
              },
            },
          },
          a = {
            description = "devとprivateのタスク",
            types = {
              {
                type = "tags",
                match = "weekly",
                org_agenda_overriding_header = "📌 今週気をつけたいこと",
              },
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = '+PRIORITY="A"|+PRIORITY="B"', -- 高優先度のタスク
                org_agenda_overriding_header = "High priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = 'private+PRIORITY="C"|dev+PRIORITY="C"',
                org_agenda_overriding_header = "Middle priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "tags_todo",
                org_agenda_overriding_header = "My dev todos",
                match = "+dev",
                -- match = '+PRIORITY="B"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                order = 10,
              },
              {
                type = "tags_todo",
                org_agenda_overriding_header = "My private todos",
                match = "+private",
                -- match = '+PRIORITY="B"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                order = 10,
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "Whole week overview",
                org_agenda_span = "week", -- 'week' is default, so it's not necessary here, just an example
                org_agenda_start_on_weekday = 1, -- Start on Monday
                org_agenda_remove_tags = true, -- Do not show tags only for this view
              },
            },
          },
          h = {
            description = "高優先度タスク",
            types = {
              {
                type = "tags_todo",
                match = '+PRIORITY="A"|+PRIORITY="B"', -- 高優先度のタスク
                order = 10,
              },
            },
          },
        },

        -- TODO状態の色設定
        org_todo_keyword_faces = {
          DOING = ":foreground orange :weight bold",
          WAITING = ":foreground yellow :weight bold",
          DONE = ":foreground green :weight bold",
          CANCELLED = ":foreground red :weight bold",
        },

        -- 優先度の色設定（nvim-orgmodeでは直接ハイライトグループを設定）

        -- よく使うキーマップ
        mappings = {
          global = {
            org_agenda = "<leader>ja", -- アジェンダを開く
            org_capture = "<leader>jc", -- 新しいタスクを追加
          },
          agenda = {
            -- bキーをvimのデフォルト動作（前の単語）に戻す
            org_agenda_earlier = {}, -- bキーのマッピングを無効化（空の配列で無効化）
            -- org_agenda_later = "f", -- 次の期間に進む（デフォルトのまま）
            org_agenda_todo = "t", -- todo状態を順方向に切り替え
          },
          org = {
            org_todo = "t", -- todo状態を切り替え
            org_priority = "<leader>jp", -- 優先度を設定
            org_set_tags_command = "<leader>jt", -- タグを設定
            org_priority_up = "+", -- 優先度を上げる
            org_priority_down = "-", -- 優先度を下げる
            org_add_note = "<leader>jn", -- ノート追加
            org_clock_in = "<leader>ji", -- クロック開始
            org_clock_out = "<leader>jo", -- クロック終了
            org_clock_cancel = "<leader>jq", -- クロックキャンセル
          },
        },
      })

      -- ファイル直接アクセス用キーマップ（シンプル化）
      vim.keymap.set(
        "n",
        "<leader>jt",
        ":e ~/src/github.com/happy663/org-memo/org/todo.org<CR>",
        { desc = "Open todo.org" }
      )
      vim.keymap.set(
        "n",
        "<leader>jb",
        ":e ~/src/github.com/happy663/org-memo/org/calendar-beorg.org<CR>",
        { desc = "Open calendar-beorg.org" }
      )
      vim.keymap.set(
        "n",
        "<leader>jn",
        ":e ~/src/github.com/happy663/org-memo/org/weekly-notes.org<CR>",
        { desc = "Open weekly-notes.org" }
      )

      -- ログディレクトリ作成
      vim.fn.system("mkdir -p ~/src/github.com/happy663/org-memo/org/logs/tasks")

      -- ============================================
      -- ステータス同期機能（ログ → todo.org）
      -- ============================================

      -- ログファイルからtodo.orgへのステータス同期
      local function sync_status_from_log()
        local filename = vim.fn.expand("%:t")
        print("Checking file: " .. filename)
        -- task-XXX-*.org形式のファイルのみ処理
        if not filename:match("^task%-") then
          print("Not a task file, skipping")
          return
        end

        -- ログファイルからIDとステータスを取得
        local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
        local id, status

        for _, line in ipairs(lines) do
          id = id or line:match("^#%+ID:%s*(.+)")
          status = status or line:match("^#%+STATUS:%s*(.+)")
          if id and status then
            break
          end
        end

        print(string.format("Found ID: %s, Status: %s", id or "nil", status or "nil"))

        if not id or not status then
          print("Missing ID or STATUS")
          return
        end

        -- ステータスの正規化（大文字に統一、空白除去）
        status = status:gsub("^%s+", ""):gsub("%s+$", ""):upper()

        -- 有効なステータスかチェック
        local valid_statuses = { TODO = true, DOING = true, WAITING = true, DONE = true, CANCELLED = true }
        if not valid_statuses[status] then
          print("Invalid status: " .. status)
          return
        end

        -- todo.orgを読み込んで更新
        local todo_file = vim.fn.expand("~/src/github.com/happy663/org-memo/org/todo.org")
        local todo_lines = vim.fn.readfile(todo_file)
        local updated = false

        print("Searching for ID in todo.org: " .. id)

        -- IDでタスクを検索
        print("Total lines in todo.org: " .. #todo_lines)
        for i, line in ipairs(todo_lines) do
          -- デバッグ：ID行の周辺のみ表示
          if line:match(":ID:") then
            print("Line " .. i .. " contains ID: " .. line)
            -- IDを抽出して比較
            local found_id = line:match(":ID:%s*([%w%-]+)")
            if found_id then
              print("  Extracted ID: '" .. found_id .. "', Looking for: '" .. id .. "'")
              if found_id == id then
                print("✓ Found matching ID at line " .. i .. ": " .. line)
                -- IDが見つかったら、その上のタスク行を探す
                for j = i - 1, math.max(1, i - 10), -1 do
                  if todo_lines[j]:match("^%*+%s+%w+") then
                    -- タスク行のステータスを更新
                    local old_line = todo_lines[j]
                    local old_status = old_line:match("^%*+%s+(%w+)")
                    print(string.format("Found task at line %d: %s", j, old_line))
                    print(string.format("Changing status from %s to %s", old_status, status))
                    todo_lines[j] = todo_lines[j]:gsub("^(%*+%s+)%w+", "%1" .. status)
                    updated = true
                    print(string.format("✅ Status synced to todo.org: %s -> %s (ID: %s)", old_status, status, id))
                    break
                  end
                end
                break
              end
            end
          end
        end

        if not updated then
          print("❌ Failed to update status - ID not found or task line not found")
        end

        -- 変更があれば保存
        if updated then
          vim.fn.writefile(todo_lines, todo_file)

          -- todo.orgが開いているバッファがあれば再読み込み
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_name(buf):match("todo%.org$") then
              vim.api.nvim_buf_call(buf, function()
                -- 現在のカーソル位置を保存
                local cursor = vim.api.nvim_win_get_cursor(0)
                vim.cmd("edit!")
                -- カーソル位置を復元
                vim.api.nvim_win_set_cursor(0, cursor)
              end)
              break
            end
          end
        end
      end

      -- ログファイル保存時のautocmd
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*/org/logs/tasks/task-*.org",
        callback = function()
          print("Syncing status from log to todo.org...")
          sync_status_from_log()
        end,
        desc = "Sync status from log file to todo.org",
      })

      -- ============================================
      -- タスク・ログ管理システム
      -- ============================================

      -- ID生成用の関数（モジュールから読み込み）
      local get_next_task_id_module = require("utils.get_next_task_id")
      local get_next_task_id = get_next_task_id_module.get_next_task_id

      -- タスクログ検索（Telescope）- jlプレフィックスに変更
      vim.keymap.set("n", "<leader>jl", function()
        require("telescope.builtin").find_files({
          prompt_title = "Find Task Log",
          cwd = vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/tasks/"),
        })
      end, { desc = "Find task log with Telescope" })

      -- タスク内容検索（Telescope）- jsプレフィックスに変更
      vim.keymap.set("n", "<leader>js", function()
        require("telescope.builtin").live_grep({
          prompt_title = "Search in Task Logs",
          cwd = vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/"),
        })
      end, { desc = "Search task log content" })

      -- 時刻ヘッダー挿入機能
      vim.keymap.set("n", "<leader>jm", function()
        local time = os.date("** [%Y-%m-%d %a %H:%M]")
        vim.api.nvim_put({ time, "" }, "l", true, true)
        vim.cmd("startinsert!")
      end, { desc = "Insert timestamp header" })

      -- タスクログ作成（改良版 - ファイル直接編集でID保存）
      -- タスク名をパースする関数（改良版を使用）
      local parse_task_name_module = require("utils.parse_task_name_improved")
      local parse_task_name = parse_task_name_module.parse_task_name

      -- 既存のIDをチェックする関数
      local function check_existing_id(current_line_num)
        for i = current_line_num, current_line_num + 10 do
          local prop_line = vim.fn.getline(i)
          if prop_line:match(":END:") then
            break
          end
          local found_id = prop_line:match(":ID:%s*([%w%-]+)")
          if found_id then
            return found_id
          end
        end
        return nil
      end

      -- 既存のログファイルを検索する関数
      local function find_existing_log_files(search_name, existing_id)
        local logs_dir = vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/tasks/")

        -- 既存IDでログファイルを探す
        if existing_id then
          local log_pattern = vim.fn.expand(string.format("%s%s-*.org", logs_dir, existing_id))
          local files = vim.fn.glob(log_pattern, false, true)
          if #files > 0 then
            return files, "id"
          end
        end

        -- タスク名ベースで検索
        local all_files = vim.fn.glob(logs_dir .. "*.org", false, true)
        local matching_files = {}

        for _, file in ipairs(all_files) do
          local basename = vim.fn.fnamemodify(file, ":t"):lower()
          if basename:match(search_name:sub(1, 10)) then
            table.insert(matching_files, file)
          end
        end

        return matching_files, "name"
      end

      -- todo.orgにIDを保存する関数
      local function save_id_to_todo(task_name, current_line_num, id)
        local todo_file = vim.fn.expand("~/src/github.com/happy663/org-memo/org/todo.org")
        local todo_lines = vim.fn.readfile(todo_file)

        -- タスクの実際の行を検索
        local actual_line_num = nil
        for i, line in ipairs(todo_lines) do
          if line:find(task_name:sub(1, 20), 1, true) then
            actual_line_num = i
            break
          end
        end

        if not actual_line_num then
          print("ERROR: Could not find task in todo.org")
          actual_line_num = current_line_num
        end

        -- プロパティブロックを挿入
        table.insert(todo_lines, actual_line_num + 1, "   :PROPERTIES:")
        table.insert(todo_lines, actual_line_num + 2, "   :ID: " .. id)
        table.insert(todo_lines, actual_line_num + 3, "   :END:")

        -- ファイルに書き戻す
        local success = vim.fn.writefile(todo_lines, todo_file)
        if success == 0 then
          print("Successfully wrote ID to todo.org: " .. id)
        else
          print("ERROR: Failed to write to todo.org")
        end

        -- todo.orgバッファが開いていれば再読み込み
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf):match("todo%.org$") then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("edit!")
            end)
            break
          end
        end
      end

      -- 新規ログファイルを作成する関数
      local function create_new_log_file(id, filename, task_name)
        local full_filename = string.format("%s-%s.org", id, filename)
        local filepath =
          vim.fn.expand(string.format("~/src/github.com/happy663/org-memo/org/logs/tasks/%s", full_filename))

        vim.cmd("e " .. filepath)

        -- テンプレート挿入
        local template = {
          "#+TITLE: " .. task_name:sub(1, 50),
          "#+ID: " .. id,
          "#+CREATED: " .. os.date("%Y-%m-%d"),
          "#+STATUS: TODO",
          "",
          "* Description",
          task_name,
          "",
          "* Log",
          "** " .. os.date("[%Y-%m-%d %a %H:%M]"),
          "Task created",
          "",
        }
        vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
        print("Created new log: " .. full_filename)
      end

      -- メインのキーマップ関数
      vim.keymap.set("n", "<leader>tl", function()
        local line = vim.fn.getline(".")
        local task_name, search_name = parse_task_name(line)
        print("Parsed task name: " .. (task_name or "nil") .. ", search name: " .. (search_name or "nil"))

        if not task_name then
          print("Cannot parse task name")
          return
        end

        -- 現在の行番号を保存（todo.orgでの位置）
        local current_line_num = vim.fn.line(".")

        -- IDがすでにあるか確認
        local existing_id = check_existing_id(current_line_num)

        -- 既存のログファイルを検索
        local matching_files, match_type = find_existing_log_files(search_name, existing_id)

        if #matching_files > 0 then
          if match_type == "id" then
            vim.cmd("e " .. matching_files[1])
            print("Opened existing log with ID: " .. existing_id)
            return
          elseif #matching_files == 1 then
            vim.cmd("e " .. matching_files[1])
            print("Opened existing log: " .. vim.fn.fnamemodify(matching_files[1], ":t"))
            return
          else
            -- print("Multiple logs found. Opening telescope...")
            -- local logs_dir = vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/tasks/")
            -- require("telescope.builtin").find_files({
            --   prompt_title = "Select Task Log",
            --   cwd = logs_dir,
            --   default_text = search_name,
            -- })
            -- return
          end
        end

        -- 新規作成
        local filename = vim.fn.input("Create new log file: ", search_name)
        if filename == "" then
          return
        end

        local id = get_next_task_id()

        -- todo.orgにIDを保存
        save_id_to_todo(task_name, current_line_num, id)

        -- 新規ログファイルを作成
        create_new_log_file(id, filename, task_name)
      end, { desc = "Create task log (simple)" })

      -- アジェンダで逆方向のTODOトグル機能を追加
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "orgagenda",
        callback = function()
          vim.keymap.set("n", "T", function()
            local orgmode = require("orgmode")
            local agenda = orgmode.agenda
            -- _remote_editを直接呼び出して逆方向のTODOトグルを実行
            agenda:_remote_edit({
              action = "org_mappings.todo_prev_state",
              update_in_place = true,
            })
          end, { buffer = true, desc = "逆方向TODO状態切り替え" })
        end,
      })
    end,
  },
}
