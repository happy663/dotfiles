return {
  {
    "subnut/nvim-ghost.nvim",
    init = function()
      vim.g.nvim_ghost_autostart = 1
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
    end,
  },
}
