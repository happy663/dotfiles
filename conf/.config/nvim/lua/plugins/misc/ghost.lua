return {
  {
    "subnut/nvim-ghost.nvim",
    init = function()
      vim.g.nvim_ghost_autostart = 0
    end,
    cond = vim.g.not_in_vscode,
    config = function()
      vim.api.nvim_create_augroup("nvim_ghost_user_autocommands", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = { "*github.com", "*zenn.dev", "*qiita.com" },
        group = "nvim_ghost_user_autocommands",
        callback = function()
          vim.opt.filetype = "markdown"
        end,
      })

      -- plugin/nvim_ghost.vim が無条件にプロセス環境へ書き込む $NVIM_LISTEN_ADDRESS を除去する。
      -- 残っていると :restart が spawn する新プロセスが address already in use で即死し、
      -- 再起動が中断されて設定変更が反映されない（issue #284）
      vim.env.NVIM_LISTEN_ADDRESS = nil

      -- ghost のヘルパーバイナリは spawn 時の環境から $NVIM_LISTEN_ADDRESS を読むため、
      -- 起動の間だけ復元するラッパー。GhostTextStart 内の jobstart は同期的に走るので
      -- 直後に unset してよい（バイナリ再インストール時のみ非同期になるが稀なので許容）
      vim.api.nvim_create_user_command("GhostStart", function()
        if vim.fn.exists(":GhostTextStart") ~= 2 then
          vim.notify("GhostTextStart is not available (already started?)", vim.log.levels.WARN)
          return
        end
        vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
        vim.cmd("GhostTextStart")
        vim.env.NVIM_LISTEN_ADDRESS = nil
      end, { desc = "Start nvim-ghost ($NVIM_LISTEN_ADDRESS を一時復元して起動)" })
    end,
  },
}
