return {
  {
    "h3pei/trace-pr.nvim",
    config = function()
      require("trace-pr").setup({})
      vim.keymap.set("n", "<leader>gt", "<cmd>TracePR<cr>", { desc = "Trace PR" })
    end,
  },
}
