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
          "~/src/github.com/happy663/org-memo/org/work.org",
          "~/src/github.com/happy663/org-memo/org/private.org",
          "~/src/github.com/happy663/org-memo/org/dev.org",
          "~/src/github.com/happy663/org-memo/org/daily.org",
        },
        org_default_notes_file = "~/src/github.com/happy663/org-memo/org/private.org", -- デフォルトのタスクファイル
        org_capture_templates = {
          w = {
            description = "仕事タスク",
            template = "* TODO [#C] %? [/] :work:",
            target = "~/src/github.com/happy663/org-memo/org/work.org",
          },
          p = {
            description = "プライベートタスク",
            template = "* TODO [#C] %? [/] :private:",
            target = "~/src/github.com/happy663/org-memo/org/private.org",
          },
          d = {
            description = "開発環境タスク",
            template = "* TODO [#C] %? [/] :dev:",
            target = "~/src/github.com/happy663/org-memo/org/dev.org",
          },
          n = {
            description = "日次報告",
            target = "~/src/github.com/happy663/org-memo/org/daily.org",
          },
        },
        -- 初心者向けの簡単な設定
        org_todo_keywords = { "TODO", "DOING", "|", "DONE" }, -- タスクの状態
        org_priority_highest = "A", -- 最高優先度
        org_priority_default = "C", -- デフォルト優先度
        org_priority_lowest = "C", -- 最低優先度
        -- 統計クッキー（チェックリスト%表示）の自動更新を有効化
        org_startup_folded = "showeverything",
        org_log_done = "time", -- DONE時にタイムスタンプを追加
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

        -- TODO/DOINGの個別色設定
        org_todo_keyword_faces = {
          DOING = ":foreground orange :weight bold",
          DONE = ":foreground green :weight bold",
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
          },
        },
      })

      -- ファイル直接アクセス用キーマップ
      vim.keymap.set(
        "n",
        "<leader>jw",
        ":e ~/src/github.com/happy663/org-memo/org/work.org<CR>",
        { desc = "Open work.org" }
      )
      vim.keymap.set(
        "n",
        "<leader>jp",
        ":e ~/src/github.com/happy663/org-memo/org/private.org<CR>",
        { desc = "Open private.org" }
      )
      vim.keymap.set(
        "n",
        "<leader>jd",
        ":e ~/src/github.com/happy663/org-memo/org/dev.org<CR>",
        { desc = "Open dev.org" }
      )
    end,
  },
}

