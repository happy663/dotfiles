return {
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = {
      "vim-denops/denops.vim",
    },
  },
  {
    "easymotion/vim-easymotion",
  },
  {
    "skanehira/jumpcursor.vim",
  },
  {
    "phaazon/hop.nvim",
    branch = "v2", -- optional but strongly recommended
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
    end,
  },
}
