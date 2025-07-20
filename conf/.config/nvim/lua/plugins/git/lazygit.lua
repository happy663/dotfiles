return {
  {
    "kdheepak/lazygit.nvim",
    cond = vim.g.not_in_vscode,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<Leader>l", "<cmd>LazyGit<CR>" },
    },
    config = function()
      -- telescopeがロードされている場合のみ拡張をロード
      if pcall(require, "telescope") then
        require("telescope").load_extension("lazygit")
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*lazygit*",
        callback = function()
          local opts = { noremap = true, silent = true }
          vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<esc>", opts)
        end,
      })

      -- lazygit終了時のコールバック設定
      vim.g.lazygit_on_exit_callback = function()
        -- ウィンドウレイアウトの修復
        vim.schedule(function()
          -- フローティングウィンドウやターミナルバッファをクリーンアップ
          for _, win in pairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.api.nvim_buf_get_option(buf, "filetype")
              local name = vim.api.nvim_buf_get_name(buf)

              -- 不要なバッファタイプを削除
              if ft == "lazygit" or ft == "cmp_menu" or ft == "NvimSeparator" or name == "" then
                if vim.api.nvim_buf_is_valid(buf) and #vim.api.nvim_list_wins() > 1 then
                  pcall(vim.api.nvim_win_close, win, true)
                end
              end
            end
          end

          -- メインエディタウィンドウにフォーカス
          for _, win in pairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.api.nvim_buf_get_option(buf, "filetype")
              if ft == "lua" or ft == "python" or ft == "javascript" or ft ~= "NvimTree" then
                vim.api.nvim_set_current_win(win)
                break
              end
            end
          end
        end)
      end
    end,
  },
}
