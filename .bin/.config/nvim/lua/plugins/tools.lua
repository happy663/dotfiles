return {
  {
    "brglng/vim-im-select",
  },
  {
    "CRAG666/code_runner.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    config = function()
      require("code_runner").setup({
        filetype = {
          java = {
            "cd $dir &&",
            "javac $fileName &&",
            "java $fileNameWithoutExt",
          },
          python = "python3 -u",
          typescript = "deno run",
          rust = {
            "cd $dir &&",
            "rustc $fileName &&",
            "$dir/$fileNameWithoutExt",
          },
          c = { "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt" },
        },
      })
    end,
  },
  {
    "glidenote/memolist.vim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    config = function()
      vim.g.memolist_path = "~/.memolist/memo"
      vim.g.memolist_memo_suffix = "md"
      vim.g.memolist_fzf = 1
      vim.g.memolist_template_dir_path = "~/.memolist/memotemplates"
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    cond = vim.g.not_in_vscode, -- VSCodeの外でのみ読み込む
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
}
