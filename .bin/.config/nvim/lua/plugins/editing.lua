-- 編集効率を高めるプラグイン

return {
  {
    "kylechui/nvim-surround",
    version = "*",
    config = true,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    -- config = function()
    --   local get_option = vim.filetype.get_option
    --   vim.filetype.get_option = function(filetype, option)
    --     return option == "commentstring" and require("ts_context_commentstring.internal").calculate_commentstring()
    --       or get_option(filetype, option)
    --   end
    -- end,
  },
  {
    "tversteeg/registers.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("registers").setup()
    end,
  },
  {
    "vim-skk/skkeleton", -- skkeleton プラグインの GitHub リポジトリ
    cond = vim.g.not_in_vscode,
    dependencies = {
      { "vim-denops/denops.vim" },
    },
  },
}
