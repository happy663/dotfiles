return {
  {
    "lambdalisue/vim-kensaku-search",
    dependencies = {
      "lambdalisue/vim-kensaku",
    },
    keys = {
      { "<CR>", "<Plug>(kensaku-search-replace)<CR>", mode = "c", desc = "Kensaku search replace" },
    },
  },
}
