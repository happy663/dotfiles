return {
  {
    "kdheepak/lazygit.nvim",
    cond = vim.g.not_in_vscode,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<Leader>l", "<cmd>LazyGit<CR>" },
    },
    config = function()
      -- telescopeがロードされている場合のみ拡張をロード
      if pcall(require, "telescope") then
        require("telescope").load_extension("lazygit")
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*lazygit*",
        callback = function()
          local opts = { noremap = true, silent = true }
          vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<esc>", opts)
        end,
      })
    end,
  },
}
