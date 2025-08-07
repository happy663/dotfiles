return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "clangd",
          "debugpy",
          "eslint-lsp",
          --"eslint_d",
          "gopls",
          --"latexindent",
          --"ltex-ls",
          "lua-language-server",
          --"luacheck",
          "prettierd",
          "pyright",
          "staticcheck",
          "stylua",
          -- "typescript-language-server",
          "nil",
          "nixpkgs-fmt",
          "vtsls",
          "intelephense",
          "php-cs-fixer",
          "denols",
          "ktlint",
        },
      })
    end,
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
  },
}
