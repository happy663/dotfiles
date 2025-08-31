return {
  {
    "nvim-orgmode/orgmode",
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
        },
        org_default_notes_file = "~/src/github.com/happy663/org-memo/org/todo.org", -- デフォルトのタスクファイル
        org_capture_templates = {
          t = {
            description = "タスク追加",
            template = "** TODO [#C] %? [/] :%^{タグ|work|dev|private}:",
            target = "~/src/github.com/happy663/org-memo/org/todo.org",
            headline = "%^{カテゴリ|Work|Dev|Private}",
          },
          q = {
            description = "クイックメモ",
            template = "* [%<%Y-%m-%d %a %H:%M>] %?\n",
            target = "~/src/github.com/happy663/org-memo/org/logs/quick.org",
          },
          l = {
            description = "作業ログ付きタスク",
            template = [[** TODO [#C] %? [/] :%^{タグ|work|dev|private}:
   :LOGBOOK:
   - Note taken on [%U] \\
     開始: 
  :END:]],
            target = "~/src/github.com/happy663/org-memo/org/todo.org",
            headline = "%^{カテゴリ|Work|Dev|Private}",
          },
        },
        -- タスク状態（作業ログ対応）
        org_todo_keywords = { "TODO(t)", "DOING(s!)", "WAITING(w@)", "|", "DONE(d!)", "CANCELLED(c@)" }, -- ! = タイムスタンプ記録, @ = ノート記録
        org_priority_highest = "A", -- 最高優先度
        org_priority_default = "C", -- デフォルト優先度
        org_priority_lowest = "C", -- 最低優先度
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
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = '+PRIORITY="A"|+PRIORITY="B"', -- 高優先度のタスク
                org_agenda_overriding_header = "High priority todos",
                org_agenda_todo_ignore_deadlines = "far", -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "My daily agenda",
                org_agenda_span = "day", -- can be any value as org_agenda_span
              },
              {
                type = "tags",
                match = "work", --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_overriding_header = "My work todos",
                org_agenda_todo_ignore_scheduled = "all", -- Ignore all headlines that are scheduled. Possible values: past | future | all
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
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = '+PRIORITY="A"|+PRIORITY="B"', -- 高優先度のタスク
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
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = '+PRIORITY="A"|+PRIORITY="B"', -- 高優先度のタスク
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
            description = "開発のタスク",
            types = {
              {
                type = "tags_todo", -- Type can be agenda | tags | tags_todo
                match = '+PRIORITY="A"|+PRIORITY="B"', -- 高優先度のタスク
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

        -- よく使うキーマップ
        mappings = {
          global = {
            org_agenda = "<leader>ja", -- アジェンダを開く
            org_capture = "<leader>jc", -- 新しいタスクを追加
          },
          org = {
            org_todo = "t", -- TODO状態を切り替え
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

      -- Git更新関数（非同期）
      local function org_git_update()
        local org_memo_dir = vim.fn.expand("~/src/github.com/happy663/org-memo")

        local commands = {
          { "git", "add", "." },
          { "git", "commit", "-m", "auto update from nvim" },
          { "git", "push", "origin", "main" },
        }

        local function run_commands(cmd_list, index)
          if index > #cmd_list then
            print("Org files updated and pushed to git!")
            return
          end

          local cmd = cmd_list[index]
          vim.system(cmd, {
            cwd = org_memo_dir,
            text = true,
          }, function(result)
            if result.code == 0 then
              -- 成功時は次のコマンドを実行
              run_commands(cmd_list, index + 1)
            else
              -- エラー時は処理を停止してエラーメッセージを表示
              print(string.format("Git command failed: %s (exit code: %d)", table.concat(cmd, " "), result.code))
              if result.stderr and result.stderr ~= "" then
                print("Error: " .. result.stderr)
              end
            end
          end)
        end

        -- 最初のコマンドから開始
        run_commands(commands, 1)
      end

      -- orgファイル保存時の自動更新設定
      -- vim.api.nvim_create_autocmd("BufWritePost", {
      --   pattern = {
      --     "*/org-memo/org/*.org",
      --   },
      --   callback = function()
      --     -- 少し遅延してからgit操作を実行（ファイル保存完了を待つ）
      --     vim.defer_fn(org_git_update, 500)
      --   end,
      --   desc = "Auto update git for org files",
      -- })

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

      -- ログディレクトリ作成
      vim.fn.system("mkdir -p ~/src/github.com/happy663/org-memo/org/logs/tasks")

      -- ============================================
      -- タスク・ログ管理システム
      -- ============================================

      -- ID生成用の関数
      local function get_next_task_id()
        local max_id = 0
        local files =
          vim.fn.glob(vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/tasks/task-*.org"), false, true)
        for _, file in ipairs(files) do
          local num = tonumber(file:match("task%-(%d+)"))
          if num and num > max_id then
            max_id = num
          end
        end
        return string.format("task-%03d", max_id + 1)
      end

      -- タスクからログを開く/作成する機能（古いバージョン - 無効化）
      --[[ vim.keymap.set("n", "<leader>tl", function()
        local line = vim.fn.getline(".")

        -- デバッグ出力
        print("Current line: " .. line)

        -- より柔軟なパターンマッチング
        local task_name = nil

        -- org-modeの特殊表示を考慮（todo: プレフィックスがある場合）
        if line:match("^%s*todo:") or line:match("^%s*done:") then
          -- org表示モードのパターン
          task_name = line:match(":%s*%w+%s+%[#[A-C]%]%s+(.-)%s+%[")
          if not task_name then
            task_name = line:match(":%s*%w+%s+(.-)%s+%[")
          end
          if not task_name then
            task_name = line:match(":%s*%w+%s+%[#[A-C]%]%s+(.-)$")
          end
          if not task_name then
            task_name = line:match(":%s*%w+%s+(.-)$")
          end
        else
          -- 通常のorgファイル形式
          -- パターン1: 優先度付き with タグ
          task_name = line:match("%*+ %w+ %[#[A-C]%] (.-)%s+:")

          -- パターン2: 優先度なし with タグ
          if not task_name then
            task_name = line:match("%*+ %w+ (.-)%s+:")
          end

          -- パターン3: タグなし（行末まで）
          if not task_name then
            task_name = line:match("%*+ %w+ %[#[A-C]%] (.-)$")
          end

          if not task_name then
            task_name = line:match("%*+ %w+ (.-)$")
          end
        end

        if not task_name or task_name == "" then
          print("Not on a task line or cannot parse task name")
          print("Line pattern not matched: " .. line)
          return
        end

        -- タスク名のクリーンアップ（[/]やタグを除去）
        task_name = task_name:gsub("%[.-%]", ""):gsub(":%w+:", ""):gsub("^%s+", ""):gsub("%s+$", "")
        print("Task name found: " .. task_name)

        -- IDプロパティを確認
        local id = nil
        local current_line = vim.fn.line(".")
        for i = current_line, current_line + 10 do
          local prop_line = vim.fn.getline(i)
          if prop_line:match(":END:") then
            break
          end
          local found_id = prop_line:match(":ID:%s*([%w%-]+)")
          if found_id then
            id = found_id
            break
          end
        end

        -- IDがなければ作成
        if not id then
          id = get_next_task_id()
          -- タスクの下にPROPERTIESを挿入
          local indent = line:match("^(%*+)") or "*"
          local properties = {
            "   :PROPERTIES:",
            "   :ID: " .. id,
            "   :END:",
          }

          -- 一時的にmodifiableを有効にする
          local was_modifiable = vim.bo.modifiable
          vim.bo.modifiable = true

          -- プロパティを挿入
          local success, err = pcall(function()
            vim.fn.append(vim.fn.line("."), properties)
          end)

          -- modifiableを元に戻す
          vim.bo.modifiable = was_modifiable

          if success then
            print("Created ID: " .. id)
          else
            print("Failed to create ID: " .. tostring(err))
            print("Please add manually: :ID: " .. id)
          end
        end

        -- ログファイルを開く/作成
        local log_pattern =
          vim.fn.expand(string.format("~/src/github.com/happy663/org-memo/org/logs/tasks/%s-*.org", id))
        local files = vim.fn.glob(log_pattern, false, true)

        if #files > 0 then
          vim.cmd("e " .. files[1])
        else
          -- 新規作成
          local default_name = task_name:gsub("[^%w%s]", ""):gsub("%s+", "-"):lower():sub(1, 30)
          local title = vim.fn.input("Log file name: ", default_name)
          if title == "" then
            return
          end

          local filename = string.format("%s-%s.org", id, title)
          local filepath =
            vim.fn.expand(string.format("~/src/github.com/happy663/org-memo/org/logs/tasks/%s", filename))

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
          print("Created log file: " .. filename)
        end
      end, { desc = "Open or create log for current task" }) --]]

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
      vim.keymap.set("n", "<leader>tl", function()
        local line = vim.fn.getline(".")
        local task_name = nil

        -- org表示モードのパターン
        if line:match("^%s*todo:") or line:match("^%s*done:") then
          task_name = line:match(":%s*%w+%s+%[#[A-C]%]%s+(.-)%s+%[")
          if not task_name then
            task_name = line:match(":%s*%w+%s+%[#[A-C]%]%s+(.-)$")
          end
        else
          task_name = line:match("%*+ %w+ %[#[A-C]%] (.-)%s+:")
          if not task_name then
            task_name = line:match("%*+ %w+ %[#[A-C]%] (.-)$")
          end
        end

        if not task_name then
          print("Cannot parse task name")
          return
        end

        -- タスク名をクリーンアップ
        task_name = task_name:gsub("%[.-%]", ""):gsub(":%w+:", ""):gsub("^%s+", ""):gsub("%s+$", "")
        local search_name = task_name:gsub("[^%w%s]", ""):gsub("%s+", "-"):lower():sub(1, 20)

        -- 現在の行番号を保存（todo.orgでの位置）
        local current_line_num = vim.fn.line(".")

        -- まずIDがすでにあるか確認
        local existing_id = nil
        for i = current_line_num, current_line_num + 10 do
          local prop_line = vim.fn.getline(i)
          if prop_line:match(":END:") then
            break
          end
          local found_id = prop_line:match(":ID:%s*([%w%-]+)")
          if found_id then
            existing_id = found_id
            break
          end
        end

        if existing_id then
          -- 既存IDでログファイルを探す
          local log_pattern =
            vim.fn.expand(string.format("~/src/github.com/happy663/org-memo/org/logs/tasks/%s-*.org", existing_id))
          local files = vim.fn.glob(log_pattern, false, true)
          if #files > 0 then
            vim.cmd("e " .. files[1])
            print("Opened existing log with ID: " .. existing_id)
            return
          end
        end

        -- 既存のログファイルを検索（タスク名ベース）
        local logs_dir = vim.fn.expand("~/src/github.com/happy663/org-memo/org/logs/tasks/")
        local all_files = vim.fn.glob(logs_dir .. "*.org", false, true)
        local matching_files = {}

        for _, file in ipairs(all_files) do
          local basename = vim.fn.fnamemodify(file, ":t"):lower()
          if basename:match(search_name:sub(1, 10)) then
            table.insert(matching_files, file)
          end
        end

        if #matching_files > 0 then
          if #matching_files == 1 then
            vim.cmd("e " .. matching_files[1])
            print("Opened existing log: " .. vim.fn.fnamemodify(matching_files[1], ":t"))
            return
          else
            print("Multiple logs found. Opening telescope...")
            require("telescope.builtin").find_files({
              prompt_title = "Select Task Log",
              cwd = logs_dir,
              default_text = search_name,
            })
            return
          end
        end

        -- 新規作成
        local filename = vim.fn.input("Create new log file: ", search_name)
        if filename == "" then
          return
        end

        local id = get_next_task_id()

        -- todo.orgにIDを保存（ファイル直接編集）
        local todo_file = vim.fn.expand("~/src/github.com/happy663/org-memo/org/todo.org")
        print("Reading todo.org from: " .. todo_file)

        local todo_lines = vim.fn.readfile(todo_file)
        print("File has " .. #todo_lines .. " lines, current line in buffer: " .. current_line_num)

        -- org-modeの表示行とファイルの実際の行は異なる可能性があるので、タスクのテキストで検索
        local actual_line_num = nil

        -- 現在表示されているタスク名で検索
        for i, line in ipairs(todo_lines) do
          -- タスク名の一部でマッチを試みる
          if line:find(task_name:sub(1, 20), 1, true) then
            actual_line_num = i
            print("Found task at actual line " .. i .. ": " .. line:sub(1, 60))
            break
          end
        end

        if not actual_line_num then
          print("ERROR: Could not find task '" .. task_name:sub(1, 30) .. "' in todo.org")
          print("Will use buffer line number as fallback: " .. current_line_num)
          actual_line_num = current_line_num
        end

        -- プロパティブロックを挿入（0ベースではなく1ベースのインデックス）
        table.insert(todo_lines, actual_line_num + 1, "   :PROPERTIES:")
        table.insert(todo_lines, actual_line_num + 2, "   :ID: " .. id)
        table.insert(todo_lines, actual_line_num + 3, "   :END:")

        print("Inserting ID after line " .. actual_line_num)

        -- ファイルに書き戻す
        local success = vim.fn.writefile(todo_lines, todo_file)
        if success == 0 then
          print("Successfully wrote ID to todo.org: " .. id)
        else
          print("ERROR: Failed to write to todo.org, code: " .. success)
        end

        -- ログファイルを作成
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

        -- todo.orgバッファが開いていれば再読み込み
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf):match("todo%.org$") then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("edit!")
            end)
            break
          end
        end
      end, { desc = "Create task log (simple)" })
    end,
  },
}
