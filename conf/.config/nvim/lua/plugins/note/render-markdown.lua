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
      vim.api.nvim_set_hl(0, "RenderMarkdownLink", { underline = true, fg = "#569CD6" })
      require("render-markdown").setup({
        on = {
          attach = function(ctx)
            -- 生URLをハイライト（render-markdownのlinkでは検出できないため）
            -- attachは一度だけ呼ばれるので重複しない
            vim.fn.matchadd("RenderMarkdownLink", "https\\?://[^ )>]*")
          end,
        },
        file_types = { "markdown", "codecompanion", "Avante", "octo" },
        render_modes = true,
        link = {
          enabled = true,
          hyperlink = "󰌹 ",
          highlight = "RenderMarkdownLink",
        },
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

