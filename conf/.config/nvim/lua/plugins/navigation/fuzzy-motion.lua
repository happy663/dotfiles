return {
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = {
      "vim-denops/denops.vim",
    },
    keys = {
      { "<Leader>h", "<CMD>FuzzyMotion<CR>", desc = "Fuzzy Motion" },
    },
    config = function()
      vim.cmd("let g:fuzzy_motion_matchers = ['kensaku', 'fzf']")
    end,
  },
}
