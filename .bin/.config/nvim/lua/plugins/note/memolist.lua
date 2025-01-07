return {
  {
    "glidenote/memolist.vim",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.g.memolist_path = "~/.memolist/memo"
      vim.g.memolist_memo_suffix = "md"
      vim.g.memolist_fzf = 1
      vim.g.memolist_template_dir_path = "~/.memolist/memotemplates"
    end,
  },
}
