-- lsp.lua
-- Mason and LSP configuration setup
require("mason").setup {
  ui = {
    border = "single",
  },
}
require("mason-lspconfig").setup()

local lspconfig = require "lspconfig"

-- Individual LSP server configurations
lspconfig.tsserver.setup {}

-- nvim-cmp setup for autocompletion
local cmp = require "cmp"
cmp.setup {
  snippet = {
    expand = function(args)
      -- For vsnip users
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
  },
  sorting = {
    comparators = {
      cmp.config.compare.order,
      cmp.config.compare.kind,
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.locality,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
    },
  },
}

-- Additional LSP related settings or functions can be added here
-- For example, setting up LSP keybindings, diagnostics format, etc.

-- Helper function for setting keymaps specific to LSP
local function set_lsp_keymaps(bufnr)
  local buf_map = function(mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or { noremap = true })
  end

  -- Keymaps for LSP
  buf_map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  buf_map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  buf_map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  buf_map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  -- More keymaps can be added here
end

-- Function to setup LSP servers with the above keymaps
local function setup_servers()
  require("mason-lspconfig").setup_handlers {
    function(server_name) -- Default handler for all servers
      -- 特定のLSPサーバーのカスタム設定を行う
      if server_name == "lua_ls" then
        require("lspconfig")[server_name].setup {
          on_attach = set_lsp_keymaps,
          settings = {
            Lua = {
              diagnostics = {
                -- `vim`をグローバル変数として認識させる
                globals = { "vim", "use" },
              },
            },
          },
        }
      else
        require("lspconfig")[server_name].setup {
          on_attach = set_lsp_keymaps,
        }
      end
    end,
  }
end

setup_servers()

require("lspconfig").eslint.setup {
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
}

require("lspconfig.ui.windows").default_options.border = "single"
