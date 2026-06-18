return {
  {
    -- NOTE: upstream tversteeg/registers.nvim は削除済み。happy663/registers.nvim にバックアップ済み
    -- TODO: メンテされている代替プラグインへの移行を検討
    "happy663/registers.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    keys = {
      { '"', mode = { "n", "v" } },
      { "@", mode = "n" },
    },
    config = function()
      require("registers").setup()
    end,
  },
}
