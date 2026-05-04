return {
  "shortcuts/no-neck-pain.nvim",
  config = function()
    require("no-neck-pain").setup({
      width = 150,
      autocmds = {
        enableOnVimEnter = "safe",
      },
    })

    vim.keymap.set("n", "<leader>zz", function()
      require("no-neck-pain").toggle()
    end, { desc = "Toggle NoNeckPain" })
  end,
}
