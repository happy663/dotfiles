return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- lazy = true,
    -- event = { "BufReadPost", "BufNewFile" },
    build = function()
      local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
      ts_update()
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        modules = {},
        ensure_installed = "all",
        sync_install = false,
        auto_install = false,
        ignore_install = { "ipkg" }, -- ipkgパーサーを除外（Idris用で通常不要）
        highlight = {
          enable = true,
          disable = function(lang)
            -- if lang == "latex" then
            --   return true
            -- end
            return vim.g.vscode
          end,
        },
      })

      -- foldmethodをexprに設定（Treesitterのfoldingを使用）
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
      vim.opt.foldlevel = 99 -- デフォルトでは全て展開
      vim.opt.foldlevelstart = 99 -- ファイルを開いたときは全て展開
    end,
  },
}
