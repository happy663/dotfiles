return {
  {
    "Shatur/neovim-ayu",
    cond = vim.g.not_in_vscode,
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
}
