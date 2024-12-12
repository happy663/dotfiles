return {
  {
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
    end,
  },
  {
    "lambdalisue/vim-kensaku-search",
    dependencies = {
      "lambdalisue/vim-kensaku",
    },
  },
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = {
      "vim-denops/denops.vim",
    },
  },
}
