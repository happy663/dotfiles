return {
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    lazy = false,
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = function()
      local actions = require("diffview.actions")

      -- コミット用のターミナルを開く関数
      local function open_commit_terminal(close_after)
        -- 現在のDiffviewタブのページ番号を取得
        local pagenr = vim.api.nvim_tabpage_get_number(0)

        -- Diffviewタブを強制的に閉じる（tabclose!は変更があっても閉じる）
        vim.cmd("tabclose! " .. pagenr)

        -- 新しいタブでターミナルを開く
        vim.cmd("tabnew")
        vim.cmd("terminal git commit -v -t ~/.config/git/commit_template_with_prompt_japanese.txt")

        -- Copilotのコンテキストリセット
        vim.schedule(function()
          if _G.toggle_copilot then
            print("Toggling Copilot (disable)...")
            _G.toggle_copilot() -- 1回目：無効化
            -- サーバーが確実に停止するまで待機してから再有効化
            vim.defer_fn(function()
              print("Toggling Copilot (enable)...")
              _G.toggle_copilot() -- 2回目：有効化（コンテキストリセット）
            end, 500) -- 500ms待機
          end
        end)

        -- ターミナル終了時の処理
        vim.api.nvim_create_autocmd("TermClose", {
          buffer = 0,
          once = true,
          callback = function()
            vim.cmd("bdelete!")
            if not close_after then
              vim.cmd("DiffviewOpen")
            end
          end,
        })

        -- インサートモードで開始
        vim.cmd("startinsert")
      end

      require("diffview").setup({
        keymaps = {
          view = {
            { "n", "q", actions.close, { desc = "ヘルプメニューを閉じる" } },
            { "n", "-", actions.toggle_stage_entry, { desc = "ステージング/アンステージング" } },
            {
              "n",
              "<leader>cc",
              function()
                open_commit_terminal(false)
              end,
              { desc = "コミット後にdiffview継続" },
            },
            {
              "n",
              "<leader>cC",
              function()
                open_commit_terminal(true)
              end,
              { desc = "コミット後にdiffviewを閉じる" },
            },
          },
          file_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "ヘルプメニューを閉じる" } },
            {
              "n",
              "<leader>cc",
              function()
                open_commit_terminal(false)
              end,
              { desc = "コミット後にdiffview継続" },
            },
            {
              "n",
              "<leader>cC",
              function()
                open_commit_terminal(true)
              end,
              { desc = "コミット後にdiffviewを閉じる" },
            },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "ヘルプメニューを閉じる" } },
          },
        },
      })
      vim.keymap.set("n", "<leader>df", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>dvh", "<cmd>DiffviewFileHistory<CR>", { desc = "File history" })
      vim.keymap.set("n", "<leader>dvf", "<cmd>DiffviewFileHistory --follow %<cr>", { desc = "File history %" })
      vim.keymap.set("n", "<leader>dvl", "<Cmd>.DiffviewFileHistory --follow<CR>", { desc = "Line history" })

      local function get_default_branch_name()
        local res = vim.system({ "git", "rev-parse", "--verify", "main" }, { capture_output = true }):wait()
        return res.code == 0 and "main" or "master"
      end

      -- Diff against local master branch
      vim.keymap.set("n", "<leader>dvm", function()
        vim.cmd("DiffviewOpen " .. get_default_branch_name())
      end, { desc = "Diff against master" })

      -- Diff against remote master branch
      vim.keymap.set("n", "<leader>dvM", function()
        vim.cmd("DiffviewOpen HEAD..origin/" .. get_default_branch_name())
      end, { desc = "Diff against origin/master" })
    end,
  },
}
