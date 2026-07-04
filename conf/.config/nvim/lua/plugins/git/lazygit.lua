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
      vim.g.lazygit_floating_window_scaling_factor = 1
      local lazygit_new_dir_file = vim.fn.stdpath("state") .. "/lazygit-newdir"
      vim.env.LAZYGIT_NEW_DIR_FILE = lazygit_new_dir_file

      local function sync_cwd_from_lazygit()
        if vim.fn.filereadable(lazygit_new_dir_file) ~= 1 then
          return
        end

        local lines = vim.fn.readfile(lazygit_new_dir_file)
        pcall(vim.fn.delete, lazygit_new_dir_file)

        local new_dir = lines[1]
        if not new_dir or new_dir == "" or vim.fn.isdirectory(new_dir) ~= 1 then
          return
        end

        vim.cmd("cd " .. vim.fn.fnameescape(new_dir))
      end

      -- telescopeがロードされている場合のみ拡張をロード
      if pcall(require, "telescope") then
        require("telescope").load_extension("lazygit")
      end

      -- Copilotリセット処理を共通化
      local function reset_copilot()
        if _G.reset_copilot then
          _G.reset_copilot()
        end
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*lazygit*",
        callback = function()
          print("Lazygit terminal opened")
          local opts = { noremap = true, silent = true }
          vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<esc>", opts)

          vim.schedule(function()
            reset_copilot()
          end)
        end,
      })

      -- -- コミットバッファが開いたときにCopilotをリセット
      -- -- nvrで親Neovimに開かれるため、前回のdiffキャッシュをクリアする
      -- vim.api.nvim_create_autocmd("FileType", {
      --   pattern = "gitcommit",
      --   callback = function()
      --     vim.schedule(function()
      --       reset_copilot()
      --     end)
      --   end,
      -- })

      -- lazygit終了時のコールバック設定
      vim.g.lazygit_on_exit_callback = function()
        print("Lazygit has exited")
        sync_cwd_from_lazygit()
        -- ウィンドウレイアウトの修復
        vim.schedule(function()
          -- クリーンアップ・フォーカス処理は現在のタブページ内に限定する。
          -- nvim_list_wins() は全タブのウィンドウを返すため、これを使うと
          -- lazygit を Agent タブで閉じた際に別タブへ飛んでしまう。
          local tabpage = vim.api.nvim_get_current_tabpage()

          -- フローティングウィンドウやターミナルバッファをクリーンアップ
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
            if vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.api.nvim_buf_get_option(buf, "filetype")
              local name = vim.api.nvim_buf_get_name(buf)

              -- 不要なバッファタイプを削除
              if ft == "lazygit" or ft == "cmp_menu" or ft == "NvimSeparator" or name == "" then
                if vim.api.nvim_buf_is_valid(buf) and #vim.api.nvim_tabpage_list_wins(tabpage) > 1 then
                  pcall(vim.api.nvim_win_close, win, true)
                end
              end
            end
          end

          -- lazygit.nvim は終了時に起動元ウィンドウへ戻すため、通常はそのままで良い。
          -- 現在ウィンドウが無効になった場合のみ、同じタブ内のウィンドウへフォーカスする。
          if not vim.api.nvim_win_is_valid(vim.api.nvim_get_current_win()) then
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
              if vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.api.nvim_buf_get_option(buf, "filetype")
                if ft ~= "NvimTree" then
                  vim.api.nvim_set_current_win(win)
                  break
                end
              end
            end
          end
        end)
      end
    end,
  },
}
