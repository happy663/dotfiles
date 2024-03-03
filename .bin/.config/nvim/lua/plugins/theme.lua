return {
  {
    "gruvbox-community/gruvbox",
  },
  {
    "Mofiqul/dracula.nvim",
  },
  {
    "https://codeberg.org/miyakogi/iceberg-tokyo.nvim",
  },
  {
    "Shatur/neovim-ayu",
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
        },
      })
    end,
  },
  { "projekt0n/github-nvim-theme" },
}
