return {
  {
    "Mofiqul/dracula.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      local dracula = require("dracula")
      dracula.setup({
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
        transparent_bg = true, -- default false
      })
    end,
  },
}
