return {
  {
    "nvimtools/none-ls.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      local null_ls = require("null-ls")

      local textlint = {
        method = null_ls.methods.DIAGNOSTICS,
        filetypes = { "markdown", "text", "tex", "latex" }, -- LaTeXのファイルタイプを追加
        generator = null_ls.generator({
          command = vim.fn.getcwd() .. "/node_modules/.bin/textlint",
          args = function(params)
            local config_path = vim.fn.findfile(".textlintrc", vim.fn.expand("%:p:h") .. ";")

            local args = {
              "--format",
              "json",
              "--stdin",
              "--stdin-filename",
              params.bufname,
              "--plugin",
              "latex2e",
            }

            if config_path ~= "" then
              vim.list_extend(args, { "--config", config_path })
            end

            return args
          end,
          format = "json",
          to_stdin = true,
          from_stderr = true,
          on_output = function(params)
            local diagnostics = {}
            if params.output and params.output[1] and params.output[1].messages then
              for _, message in ipairs(params.output[1].messages) do
                table.insert(diagnostics, {
                  row = message.line,
                  col = message.column,
                  end_row = message.line,
                  end_col = message.column + (message.range and message.range[1] or 1),
                  message = message.message,
                  severity = vim.diagnostic.severity.WARN,
                  source = "textlint: " .. (message.ruleId or "unknown"),
                })
              end
            end
            return diagnostics
          end,
        }),
      }

      null_ls.setup({
        debug = false,
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
          -- TODO: なんでこれがtexで動かないのかわからないので調査したい
          -- null_ls.builtins.diagnostics.textlint.with({ filetypes = { "markdown", "tex" } }),
          textlint,
        },
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
