return {
  {
    -- TODO: pluginsがarchiveされているので、代替を探す
    "phaazon/hop.nvim",
    branch = "v2", -- optional but strongly recommended
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
      vim.keymap.set("n", "<leader>f", "<CMD>HopWord<CR>", { noremap = true, silent = true })
    end,
  },
}
