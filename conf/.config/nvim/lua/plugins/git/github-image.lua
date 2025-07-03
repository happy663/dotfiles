return {
  {
    "pwntester/octo.nvim",
    optional = true,
    opts = function(_, opts)
      -- GitHub画像アップロード機能を追加

      local function github_image_upload()
        -- 現在のバッファからリポジトリURLを取得
        local bufname = vim.api.nvim_buf_get_name(0)

        -- デバッグ用: バッファ名を表示（必要に応じてコメントアウト）
        -- vim.notify("Current buffer: " .. bufname, vim.log.levels.INFO)

        -- GitHub issueのURLを構築
        local issue_url = nil
        if bufname:match("octo://") and (bufname:match("/issue/") or bufname:match("/issues/")) then
          -- octo://owner/repo/issue/123 または octo://owner/repo/issues/123 の形式からissue URLを生成
          local parts = vim.split(bufname, "/")
          if #parts >= 6 then
            local owner = parts[3]
            local repo = parts[4]
            local issue_number = parts[6]
            issue_url = "https://github.com/" .. owner .. "/" .. repo .. "/issues/" .. issue_number

            -- デバッグ用: 生成されたURLを表示（必要に応じてコメントアウト）
            -- vim.notify("Generated URL: " .. issue_url, vim.log.levels.INFO)
          end
        end

        if not issue_url then
          -- issueURLが見つからない場合は入力を求める
          issue_url = vim.fn.input("GitHub Issue URL: ")
          if issue_url == "" then
            vim.notify("GitHub Issue URLが入力されていません", vim.log.levels.ERROR)
            return
          end
        end

        -- Safari 永続セッション GitHub アップロードスクリプトパスを構築
        local script_path = vim.fn.stdpath("config") .. "/scripts/safari_persistent_upload.py"

        -- Safari 永続セッション スクリプトを非同期実行
        local cmd = { "python3", script_path, issue_url }

        vim.notify("画像をアップロード中...", vim.log.levels.INFO)

        vim.fn.jobstart(cmd, {
          on_stdout = function(_, data)
            if data and #data > 0 then
              for _, line in ipairs(data) do
                if line ~= "" then
                  -- マークダウン形式の画像URLをカーソル位置に挿入
                  local cursor_pos = vim.api.nvim_win_get_cursor(0)
                  local row = cursor_pos[1]
                  local col = cursor_pos[2]

                  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { line })
                  vim.notify("画像のアップロードが完了しました", vim.log.levels.INFO)
                end
              end
            end
          end,
          on_stderr = function(_, data)
            if data and #data > 0 then
              for _, line in ipairs(data) do
                if line ~= "" then
                  -- エラーのみ通知
                  if line:match("❌") or line:match("エラー") or line:match("Error") or line:match("失敗") then
                    vim.notify(line, vim.log.levels.ERROR)
                  end
                end
              end
            end
          end,
          on_exit = function(_, code)
            if code ~= 0 then
              vim.notify("画像アップロードに失敗しました", vim.log.levels.ERROR)
            end
          end,
        })
      end

      -- コマンドを追加
      vim.api.nvim_create_user_command("GitHubImageUpload", github_image_upload, {})

      -- キーマッピングを追加
      vim.keymap.set("n", "<leader>gi", github_image_upload, {
        desc = "GitHub画像アップロード",
        noremap = true,
        silent = true,
      })

      -- Octo.nvimのバッファでのみ有効なキーマッピング
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function()
          vim.keymap.set("n", "<leader>gi", github_image_upload, {
            desc = "GitHub画像アップロード",
            noremap = true,
            silent = true,
            buffer = true,
          })
        end,
      })

      return opts
    end,
  },
}
