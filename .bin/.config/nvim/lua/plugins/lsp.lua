local function set_lsp_keymaps(bufnr)
  local buf_map = function(mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or { noremap = true })
  end

  -- Keymaps for LSP
  buf_map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  buf_map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  --buf_map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  buf_map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
end

local on_attach = function(client, bufnr)
  set_lsp_keymaps(bufnr)

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    -- 枠のスタイルを指定: single, double, rounded, solid, shadow など
    border = "single",
  })
end

return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          border = "single",
        },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup_handlers({
        function(server_name) -- Default handler for all servers
          -- 特定のLSPサーバーのカスタム設定を行う
          if server_name == "lua_ls" then
            require("lspconfig")[server_name].setup({
              on_attach = on_attach,
              settings = {
                Lua = {
                  diagnostics = {
                    -- `vim`をグローバル変数として認識させる
                    globals = { "vim", "use" },
                  },
                },
              },
            })
          else
            require("lspconfig")[server_name].setup({
              on_attach = on_attach,
            })
          end
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").eslint.setup({
        on_attach = function(client, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      })
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.completion.spell,
          null_ls.builtins.formatting.prettierd,
          null_ls.builtins.code_actions.eslint_d,
          null_ls.builtins.formatting.latexindent,
          null_ls.builtins.diagnostics.luacheck.with({
            extra_args = { "--globals", "vim", "--globals", "use" },
          }),
        },
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua",
          "textlint",
          "prettierd",
          "eslint_d",
        },
      })
    end,
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
  },
}
