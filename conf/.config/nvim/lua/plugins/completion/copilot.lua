return {
  {
    "zbirenbaum/copilot.lua",
    cmd = { "Copilot" },
    event = { "InsertEnter" },
    cond = vim.g.not_in_vscode,
    config = function()
      require("copilot").setup({
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
            next = "<M-CR>",
          },
        },
        filetypes = {
          gitcommit = true,
          tex = false,
          markdown = false,
        },
      })
    end,
  },
}
