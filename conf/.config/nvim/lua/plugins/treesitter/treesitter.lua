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
    end,
  },
}
