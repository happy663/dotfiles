return {
  "jedrzejboczar/possession.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local restart_cmd = nil
    require("possession").setup({
      -- セッション保存の基本設定
      autosave = {
        current = true, -- 現在のセッションを自動保存
        on_load = true, -- セッション読み込み時も自動保存を有効化
        on_quit = true, -- 終了時に自動保存
      },
      -- autoload = "auto_cwd", -- 起動時に前回のセッションを自動復元
    })

    vim.api.nvim_create_user_command("Restart", function()
      if vim.fn.has("gui_running") then
        if restart_cmd == nil then
          vim.notify("Restart command not found", vim.log.levels.WARN)
        end
      end

      require("possession.session").save("restart", { no_confirm = true })
      vim.cmd([[qa!]])
    end, {})

    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        -- possession.nvimの初期化を待つため遅延実行
        vim.schedule(function()
          -- ファイルシステムから直接チェック
          local session_dir = vim.fn.stdpath("data") .. "/possession"
          local restart_file = session_dir .. "/restart.json"

          vim.notify("Checking for restart file: " .. restart_file, vim.log.levels.INFO)

          -- ファイルが存在するかチェック
          if vim.fn.filereadable(restart_file) == 1 then
            vim.notify("Restart file found! Loading session...", vim.log.levels.INFO)

            -- possession.nvimを明示的にロード
            local ok, session = pcall(require, "possession.session")
            if ok then
              session.load("restart")
              session.delete("restart", { no_confirm = true })
              vim.opt.cmdheight = 1
              vim.notify("Restart session loaded and deleted.", vim.log.levels.INFO)
            else
              vim.notify("Failed to load possession.session module", vim.log.levels.ERROR)
            end
          else
            vim.notify("No restart file found.", vim.log.levels.INFO)
          end
        end)
      end,
    })
  end,
}
