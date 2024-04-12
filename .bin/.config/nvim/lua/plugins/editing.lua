-- 編集効率を高めるプラグイン

return {
  {
    "kylechui/nvim-surround",
    version = "*",
    config = true,
  },
  {
    "numToStr/Comment.nvim",
    config = true,
  },
  {
    "tversteeg/registers.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("registers").setup()
    end,
  },
  {
    "vim-skk/skkeleton", -- skkeleton プラグインの GitHub リポジトリ
    config = function()
      -- skkeleton の初期化関数を定義
      local function skkeleton_init()
        vim.fn["skkeleton#config"]({
          -- 改行キーでの確定のみを有効にする
          eggLikeNewline = true,
          -- ユーザー辞書のパス
          userDictionary = "~/.config/skk/dictionary/SKK-JISYO.L",
          -- 辞書データベースの保存先
          databasePath = "~/.config/skk/db",
        })
      end
      -- イベントに応じたフックの設定
      vim.api.nvim_create_augroup("SkkeletonInitialize", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = "SkkeletonInitialize",
        pattern = "skkeleton-initialize-pre",
        callback = skkeleton_init,
      })
    end,
  },
}
