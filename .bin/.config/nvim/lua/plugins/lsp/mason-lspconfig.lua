local function set_lsp_keymaps(bufnr)
  local buf_map = function(mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or { noremap = true })
  end

  buf_map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  buf_map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  buf_map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  buf_map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  buf_map("n", "<C-k>", "<cmd>lua vim.lsp.buf.hover()<CR>")
  buf_map("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
end

local no_format_on_attach = function(client, bufnr)
  set_lsp_keymaps(bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "double",
  })
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "<leader>di",
    '<cmd>lua vim.diagnostic.open_float(nil, {focus=true, border="double"})<CR>',
    { noremap = true, silent = true }
  )
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
    virtual_text = {
      format = function(diagnostic)
        return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
      end,
    },
  })
end

local on_attach = function(client, bufnr)
  set_lsp_keymaps(bufnr)
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "double",
  })
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "<leader>di",
    '<cmd>lua vim.diagnostic.open_float(nil, {focus=true, border="double"})<CR>',
    { noremap = true, silent = true }
  )
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
    virtual_text = {
      format = function(diagnostic)
        return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
      end,
    },
  })
end

return {
  {
    "williamboman/mason-lspconfig.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      local lspconfig = require("lspconfig")
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({
            on_attach = on_attach,
          })
        end,
        lua_ls = function()
          lspconfig.lua_ls.setup({
            on_attach = no_format_on_attach,
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim", "use" },
                },
              },
            },
          })
        end,
        -- tsserver = function()
        --   lspconfig.tsserver.setup({
        --     on_attach = no_format_on_attach,
        --   })
        -- end,
        vtsls = function()
          lspconfig.vtsls.setup({
            on_attach = no_format_on_attach,
          })
        end,
        eslint = function()
          lspconfig.eslint.setup({
            on_attach = function(client, bufnr)
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                command = "EslintFixAll",
              })
            end,
          })
        end,
        pylsp = function()
          lspconfig.pylsp.setup({
            on_attach = no_format_on_attach,
          })
        end,
        texlab = function()
          lspconfig.texlab.setup({
            on_attach = on_attach,
            root_dir = lspconfig.util.root_pattern(".texlabroot", ".git", ".latexmkrc", "texlabroot", "Tectonic.toml"),
            settings = {
              texlab = {
                build = {
                  executable = "latexmk",
                  args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                  onSave = true,
                },
              },
            },
          })
        end,
      })
    end,
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
    },
  },
}
