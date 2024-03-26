return {
  {
    "gruvbox-community/gruvbox",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
  },
  {
    "Mofiqul/dracula.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
  },
  {
    "https://codeberg.org/miyakogi/iceberg-tokyo.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
  },
  {
    "Shatur/neovim-ayu",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    config = function()
      require("ayu").setup({
        overrides = {
          Normal = { bg = "None" },
          ColorColumn = { bg = "None" },
          SignColumn = { bg = "None" },
          Folded = { bg = "None" },
          FoldColumn = { bg = "None" },
          CursorLine = { bg = "None" },
          CursorColumn = { bg = "None" },
          WhichKeyFloat = { bg = "None" },
          VertSplit = { bg = "None" },
          LineNr = { fg = "#7c869c" },
        },
      })
    end,
  },
  { "projekt0n/github-nvim-theme" },
}
