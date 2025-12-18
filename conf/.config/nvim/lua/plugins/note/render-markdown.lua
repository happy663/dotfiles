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
          -- コードブロックの左パディングを設定（折りたたみ列のスペースを確保）
          left_pad = 1,
          -- コードブロックの境界線を表示（折りたたみ時の視認性向上）
          border = "thin",
        },
        html = {
          comment = {
            conceal = false,
          },
        },
        -- 折りたたみに関する設定
        sign = {
          enabled = true, -- サイン列を有効化
        },
        -- Anti-conceal設定: 折りたたみ時もテキストを表示
        anti_conceal = {
          enabled = true,
        },
        -- ファイルタイプ別のオーバーライド設定
        overrides = {
          filetype = {
            markdown = {
              code = {
                -- 設定しないとfoldされているときにコードブロックが見えなくなってしまう
                enabled = false,
              },
            },
            -- octo専用: コードブロックのレンダリングのみ無効化
            octo = {
              code = {
                enabled = false,
              },
              win_options = {
                conceallevel = {
                  default = 0,
                  rendered = 0,
                },
                concealcursor = {
                  default = "",
                  rendered = "",
                },
              },
            },
          },
        },
      })
    end,
  },
}
