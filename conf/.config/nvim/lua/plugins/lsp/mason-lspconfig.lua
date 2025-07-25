local function format_diagnostics(diagnostics)
  local formatted = {}
  for i, d in ipairs(diagnostics) do
    table.insert(
      formatted,
      string.format("%d. [%s] Line %d: %s", i, d.severity == 1 and "ERROR" or "WARN", d.lnum + 1, d.message)
    )
  end
  return table.concat(formatted, "\n")
end

local function copy_diagnostic_text(bufnr)
  -- カーソル行を取得（0から始まるインデックスに調整）
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1

  -- 現在の行の診断情報を取得
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = cursor_line })

  -- 診断情報が存在しない場合はメッセージを表示して終了
  if #diagnostics == 0 then
    print("No diagnostics found on current line")
    return
  end

  -- 診断情報をフォーマットして文字列に変換
  local diagnostic_text = format_diagnostics(diagnostics)

  -- クリップボードにコピー
  vim.fn.setreg("+", diagnostic_text)
end

local function set_lsp_keymaps(bufnr)
  local function keymap(bufnum)
    return function(mode, lhs, rhs, opts)
      vim.api.nvim_buf_set_keymap(bufnum, mode, lhs, rhs, opts or { noremap = true, silent = true })
    end
  end
  local buf_map = keymap(bufnr)
  buf_map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  buf_map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  buf_map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  buf_map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  buf_map("n", "<C-k>", "<cmd>lua vim.lsp.buf.hover()<CR>")
  buf_map("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
  buf_map("n", "<leader>di", '<cmd>lua vim.diagnostic.open_float(nil, {focus=true, border="double"})<CR>')
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "double",
  })
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
    virtual_text = {
      format = function(diagnostic)
        return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
      end,
    },
    vertical_lines = {
      format = function(diagnostic)
        return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
      end,
    },
  })
  vim.keymap.set("n", "<leader>dcc", function()
    copy_diagnostic_text(bufnr)
  end, {
    desc = "Copy current line diagnostics",
  })

  vim.keymap.set("n", "<leader>dca", function()
    copy_diagnostic_text(bufnr)
  end, {
    desc = "Copy all diagnostics",
  })
end

local no_format_on_attach = function(client, bufnr)
  set_lsp_keymaps(bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
end

local on_attach = function(_, bufnr)
  set_lsp_keymaps(bufnr)
end

return {
  {
    "williamboman/mason-lspconfig.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = "LspAttach",
    config = function()
      local lspconfig = require("lspconfig")
      -- デフォルト設定（その他のサーバー向け）
      vim.lsp.config("*", {
        on_attach = on_attach,
        -- capabilities = require('cmp_nvim_lsp').default_capabilities(),
      })
      -- Lua設定
      vim.lsp.config("lua_ls", {
        on_attach = no_format_on_attach,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim", "use" },
            },
          },
        },
      })
      -- Tailwind CSS設定
      vim.lsp.config("tailwindcss", {
        on_attach = no_format_on_attach,
      })
      -- TypeScript Server設定
      vim.lsp.config("vtsls", {
        on_attach = no_format_on_attach,
        root_markers = {
          "tsconfig.json",
          "package.json",
        },
        workspace_required = true,
      })
      -- Deno設定
      vim.lsp.config("denols", {
        root_markers = {
          "deno.json",
          "deno.jsonc",
        },
        workspace_required = true,
        on_attach = no_format_on_attach,
        init_options = {
          lint = true,
          unstable = true,
          suggest = {
            imports = {
              hosts = {
                ["https://deno.land"] = true,
                ["https://cdn.nest.land"] = true,
                ["https://crux.land"] = true,
              },
            },
          },
        },
      })
      -- PHP設定
      vim.lsp.config("intelephense", {
        on_attach = no_format_on_attach,
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        settings = {
          intelephense = {
            format = {
              -- これがないと、PHPのintelephenseが無効化されない
              -- no_format_on_attachでは無効化されない
              enable = false, -- 明示的にフォーマットを無効化
            },
          },
        },
      })
      -- ESLint設定
      vim.lsp.config("eslint", {
        on_attach = function(client, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      })
      -- Python設定
      vim.lsp.config("pylsp", {
        on_attach = no_format_on_attach,
      })
      -- LaTeX設定
      vim.lsp.config("texlab", {
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
      -- Nix設定
      vim.lsp.config("nil_ls", {
        on_attach = on_attach,
      })
      -- Typos設定
      vim.lsp.config("typos_lsp", {
        init_options = {
          config = "~/.config/nvim/.typos.toml",
          diagnosticSeverity = "Warning",
        },
      })
      -- Mason-LSPConfigの設定
      require("mason-lspconfig").setup()
    end,
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
    },
  },
}
