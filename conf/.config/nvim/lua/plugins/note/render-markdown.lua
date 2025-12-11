return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    -- 遅延ロード: markdown系ファイル時のみ
    ft = { "markdown", "codecompanion", "Avante", "octo" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    config = function()
      require("render-markdown").setup({
        file_types = { "markdown", "codecompanion", "Avante", "octo" },
        render_modes = true,
        code = {
          width = "full",
        },
        html = {
          comment = {
            conceal = false,
          },
        },
      })
    end,
  },
}
