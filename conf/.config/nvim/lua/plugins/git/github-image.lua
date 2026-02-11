return {
  {
    "pwntester/octo.nvim",
    optional = true,
    -- 遅延ロード: Octoコマンド使用時のみ
    cmd = { "Octo" },
    ft = { "octo" },
    opts = function(_, opts)
      -- GitHub画像アップロード機能を追加

      local function github_image_upload()
        -- コマンド実行時のカーソル位置を保存
        local saved_cursor_pos = vim.api.nvim_win_get_cursor(0)
        local saved_bufnr = vim.api.nvim_get_current_buf()
        -- 現在のバッファからリポジトリURLを取得
        local bufname = vim.api.nvim_buf_get_name(0)

        -- デバッグ用: バッファ名を表示（必要に応じてコメントアウト）
        -- vim.notify("Current buffer: " .. bufname, vim.log.levels.INFO)

        -- GitHub issueのURLを構築
        local issue_url = nil
        
        -- 方法1: _G.octo_buffersメタデータから取得（最も確実）
        local octo_buffer = _G.octo_buffers and _G.octo_buffers[saved_bufnr]
        if octo_buffer and octo_buffer.repo and octo_buffer.number then
          local url_path = octo_buffer.kind == "pull_request" and "pull" or "issues"
          issue_url = "https://github.com/" .. octo_buffer.repo .. "/" .. url_path .. "/" .. octo_buffer.number
        -- 方法2: バッファローカル変数から取得（リネーム処理で保存された番号）
        elseif vim.b[saved_bufnr].octo_issue_number and bufname:match("octo://") then
          local parts = vim.split(bufname, "/")
          if #parts >= 5 then
            local owner = parts[3]
            local repo = parts[4]
            local kind = parts[5]
            local issue_number = vim.b[saved_bufnr].octo_issue_number
            local url_path = kind == "pull_request" and "pull" or "issues"
            issue_url = "https://github.com/" .. owner .. "/" .. repo .. "/" .. url_path .. "/" .. issue_number
          end
        -- 方法3: バッファ名から取得（フォールバック: リネームされていない場合）
        elseif bufname:match("octo://") and (bufname:match("/issue/") or bufname:match("/issues/") or bufname:match("/pull_request/")) then
          local parts = vim.split(bufname, "/")
          if #parts >= 6 then
            local owner = parts[3]
            local repo = parts[4]
            local kind = parts[5]
            local issue_number = parts[6]
            -- issue_numberが数字かどうかを確認
            if tonumber(issue_number) then
              local url_path = kind == "pull_request" and "pull" or "issues"
              issue_url = "https://github.com/" .. owner .. "/" .. repo .. "/" .. url_path .. "/" .. issue_number
            end
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
                  -- マークダウン形式の画像URLを保存したカーソル位置に挿入
                  local row = saved_cursor_pos[1]
                  local col = saved_cursor_pos[2]

                  vim.api.nvim_buf_set_text(saved_bufnr, row - 1, col, row - 1, col, { line })
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

