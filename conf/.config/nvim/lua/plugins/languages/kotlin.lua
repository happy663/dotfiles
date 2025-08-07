return {
  {
    "udalov/kotlin-vim",
    ft = { "kotlin" },
    config = function()
      -- Kotlinファイルのインデント設定
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "kotlin",
        callback = function()
          vim.opt_local.shiftwidth = 4
          vim.opt_local.tabstop = 4
          vim.opt_local.expandtab = true
        end,
      })
    end,
  },
}