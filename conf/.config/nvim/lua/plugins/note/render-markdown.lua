return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    -- 遅延ロード: markdown系ファイル時のみ
    ft = { "markdown", "codecompanion", "Avante" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    config = function()
      require("render-markdown").setup({
        file_types = { "markdown", "codecompanion", "Avante" },
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
      })

      -- Markdown用のautocmdでconcealを調整
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "codecompanion", "Avante", "octo" },
        callback = function()
          -- 折りたたみ時はconcealを無効化
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = "nc" -- ノーマル・コマンドモードでのみconceal
        end,
      })
    end,
  },
}
