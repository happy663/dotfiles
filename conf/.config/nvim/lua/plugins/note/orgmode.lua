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
        org_agenda_files = { "~/dotfiles/org/*" },
        org_default_notes_file = "~/dotfiles/org/tasks.org", -- デフォルトのタスクファイル
        org_capture_templates = {
          t = {
            description = "タスク",
            template = "** TODO %?\n   %u", -- %?はカーソル位置、%uは日時
            target = "~/dotfiles/org/tasks.org",
            headline = "タスク一覧",
          },
          w = {
            description = "仕事のタスク",
            template = "** TODO [#B] %? :仕事:\n   %u",
            target = "~/dotfiles/org/tasks.org",
            headline = "タスク一覧",
          },
        },
        -- 初心者向けの簡単な設定
        org_todo_keywords = { "TODO", "DOING", "|", "DONE" }, -- タスクの状態
        org_priority_highest = "A", -- 最高優先度
        org_priority_default = "C", -- デフォルト優先度
        org_priority_lowest = "C", -- 最低優先度
        -- カスタムアジェンダコマンド
        org_agenda_custom_commands = {
          -- wキー: 仕事のタスクだけ
          w = {
            description = "仕事のタスク",
            template = function()
              return {
                {
                  type = "tags-todo",
                  match = "+仕事",
                  order = 10,
                },
              }
            end,
          },

          -- pキー: プライベートのタスクだけ
          p = {
            description = "プライベートのタスク",
            template = function()
              return {
                {
                  type = "tags-todo",
                  match = "+プライベート",
                  order = 10,
                },
              }
            end,
          },

          -- hキー: 優先度Aのタスクだけ
          h = {
            description = "高優先度タスク",
            template = function()
              return {
                {
                  type = "tags-todo",
                  match = '+PRIORITY="A"',
                  order = 10,
                },
              }
            end,
          },
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
          },
        },
      })
    end,
  },
}
