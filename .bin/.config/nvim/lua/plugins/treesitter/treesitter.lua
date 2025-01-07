return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
      ts_update()
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = "all",
        sync_install = false,
        auto_install = false,
        ignore_install = {},
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
