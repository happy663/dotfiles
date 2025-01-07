return {
  {
    "nvimtools/none-ls.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        diagnostics_format = "#{m} (#{s}: #{c})",
        sources = {
          null_ls.builtins.formatting.stylua,
          --null_ls.builtins.completion.spell,
          null_ls.builtins.formatting.prettierd,
          --null_ls.builtins.code_actions.eslint_d,
          -- null_ls.builtins.formatting.latexindent,
          --null_ls.builtins.diagnostics.luacheck.with({
          --extra_args = { "--globals", "vim", "--globals", "use" },
          --}),
        },
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
