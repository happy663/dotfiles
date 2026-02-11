return {
  {
    "CRAG666/code_runner.nvim",
    cond = vim.g.not_in_vscode,
    cmd = "RunCode",
    keys = {
      { "<Leader>cr", "<CMD>RunCode<CR>", desc = "Run Code" },
    },
    config = function()
      require("code_runner").setup({})
    end,
  },
}
