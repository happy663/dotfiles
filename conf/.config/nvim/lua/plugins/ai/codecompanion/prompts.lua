local M = {}

function M.get(roles, short_names)
  return {
    ["Chat with Buffer"] = {
      interaction = "chat",
      description = "Open chat with current buffer automatically attached",
      opts = {
        is_default = true,
        is_slash_cmd = false, -- キーマッピングからのみ使用
        modes = { "n" },
        alias = short_names.CHAT_WITH_BUFFER,
        auto_submit = false,
        user_prompt = false,
        stop_context_insertion = false, -- 追加のコンテキストも許可
      },
      prompts = {
        {
          role = roles.USER_ROLE,
          content = "#{buffer}",
          opts = {
            contains_code = true,
          },
        },
      },
    },
    ["Refactor Code"] = {
      interaction = "chat",
      description = "Refactor the selected code to improve its structure and quality",
      opts = {
        is_default = true,
        is_slash_cmd = false,
        modes = { "v" },
        alias = short_names.REFACTOR_CHAT,
        auto_submit = true,
        user_prompt = false,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = roles.SYSTEM_ROLE,
          content = [[あなたはコード・リファクタリングの専門家です。コードをリファクタリングするときは、以下の原則に従ってください：
                1.必要に応じてSOLIDの原則を適用する
                2.デザインパターンを効果的に使用する
                3.コードのモジュール性と再利用性を向上させる。
                4.可読性と保守性を高める
                5.重複コードの削除
                6.言語固有のベスト・プラクティスに従う。
                7.元の機能を維持する
                ]],
          opts = {
            visible = false,
          },
        },
        {
          role = roles.USER_ROLE,
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(
              context.start_line,
              context.end_line,
              { show_line_numbers = true }
            )

            return string.format(
              [[Please refactor this %s code:
                     ```%s
                     %s
                     ```]],
              context.filetype,
              context.filetype,
              code
            )
          end,
          opts = {
            contains_code = true,
          },
        },
      },
    },
    ["Refactor Code Inline"] = {
      interaction = "inline",
      description = "Refactor the selected code to improve its structure and quality",
      opts = {
        is_default = true,
        is_slash_cmd = false,
        modes = { "v" },
        alias = short_names.REFACTOR_INLINE,
        auto_submit = true,
        user_prompt = false,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = roles.SYSTEM_ROLE,
          content = [[コードリファクタリングの専門家です。コードをリファクタリングする際は、以下の原則に従ってください：
                1. 適切な場所にSOLIDの原則を適用する
                2. デザインパターンを効果的に使用する
                3. コードのモジュール性と再利用性を向上させる
                4. 読みやすさと保守性を高める
                5. コードの重複を排除する
                6. 言語固有のベストプラクティスに従う
                7. 元の機能を保持する
                説明なしにリファクタリングされたコードのみを返してください。]],
          opts = {
            visible = false,
          },
        },
        {
          role = roles.USER_ROLE,
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(
              context.start_line,
              context.end_line,
              { show_line_numbers = true }
            )
            return string.format(
              [[Please refactor this %s code:
                    ```%s
                    %s
                    ```]],
              context.filetype,
              context.filetype,
              code
            )
          end,
          opts = {
            contains_code = true,
          },
        },
      },
    },
    ["Explain LSP Diagnostics"] = {
      interaction = "chat",
      description = "Explain the LSP diagnostics for the selected code",
      opts = {
        index = 9,
        is_default = true,
        is_slash_cmd = false,
        modes = { "v" },
        alias = short_names.LSP_CHAT,
        auto_submit = true,
        user_prompt = false,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = roles.SYSTEM_ROLE,
          content = [[あなたは、警告やエラーメッセージなどのコード診断を支援できる、エキスパートなコーダーで役立つアシスタントです。
                          適切な場合は、シンタックスハイライトを有効にするために、
                          言語識別子を持つフェンスされたコードブロックでコードスニペットを含むソリューションを提供します。]],
          opts = {
            visible = false,
          },
        },
        {
          role = roles.USER_ROLE,
          content = function(context)
            local diagnostics = require("codecompanion.helpers.actions").get_diagnostics(
              context.start_line,
              context.end_line,
              context.bufnr
            )

            local concatenated_diagnostics = ""
            for i, diagnostic in ipairs(diagnostics) do
              concatenated_diagnostics = concatenated_diagnostics
                .. i
                .. ". Issue "
                .. i
                .. "\n  - Location: Line "
                .. diagnostic.line_number
                .. "\n  - Buffer: "
                .. context.bufnr
                .. "\n  - Severity: "
                .. diagnostic.severity
                .. "\n  - Message: "
                .. diagnostic.message
                .. "\n"
            end

            return string.format(
              [[The programming language is %s. This is a list of the diagnostic messages:

                    %s
                    ]],
              context.filetype,
              concatenated_diagnostics
            )
          end,
        },
        {
          role = roles.USER_ROLE,
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(
              context.start_line,
              context.end_line,
              { show_line_numbers = true }
            )
            return string.format(
              [[
                    This is the code, for context:

                    ```%s
                    %s
                    ```
                    ]],
              context.filetype,
              code
            )
          end,
          opts = {
            contains_code = true,
          },
        },
      },
    },
    ["Fix LSP Inline"] = {
      interaction = "inline",
      description = "Fix LSP issues with inline changes",
      opts = {
        is_default = true,
        is_slash_cmd = false,
        modes = { "v" },
        alias = short_names.LSP_INLINE,
        auto_submit = true,
        user_prompt = false,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = roles.SYSTEM_ROLE,
          content = [[LSPの診断の問題を修正することに特化したエキスパートコーダーです。コードを修正する際は:
                1. 修正されたコードのみを提供する
                2. すべてのLSP診断が解決されることを確認する
                3. 元のコードスタイルを維持する
                4. 必要な変更のみを含める
                5. 説明やマークダウンなしで生のコードのみを返す]],
          opts = {
            visible = false,
          },
        },
        {
          role = roles.USER_ROLE,
          content = function(context)
            local diagnostics = require("codecompanion.helpers.actions").get_diagnostics(
              context.start_line,
              context.end_line,
              context.bufnr
            )

            local code = require("codecompanion.helpers.actions").get_code(
              context.start_line,
              context.end_line,
              { show_line_numbers = true }
            )

            return string.format(
              [[Fix this %s code according to the LSP diagnostics:
                    LSP Diagnostics:
                    %s
                    Code:
                    %s]],
              context.filetype,
              vim.inspect(diagnostics),
              code
            )
          end,
          opts = {
            contains_code = true,
          },
        },
      },
    },
    ["Explain"] = {
      interaction = "chat",
      description = "Explain how code in a buffer works",
      opts = {
        is_default = true,
        is_slash_cmd = false,
        modes = { "v" },
        alias = short_names.EXPLAIN_CHAT,
        auto_submit = true,
        user_prompt = false,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = roles.SYSTEM_ROLE,
          content = [[コードを説明する際は、以下の手順に従ってください：
                1. プログラミング言語を特定する。
                2. コードの目的を説明し、プログラミング言語の中心的な概念を参照する。
                3. 各関数または重要なコードブロックを説明し、パラメータと戻り値を含める。
                4. 使用された特定の関数またはメソッドとその役割を強調する。
                5. 該当する場合、コードが大きなアプリケーションにどのように適合するかについてコンテキストを提供する。]],
          opts = {
            visible = false,
          },
        },
        {
          role = roles.USER_ROLE,
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

            return string.format(
              [[Please explain this code from buffer %d:

                    ```%s
                    %s
                    ```
                    ]],
              context.bufnr,
              context.filetype,
              code
            )
          end,
          opts = {
            contains_code = true,
          },
        },
      },
    },
  }
end

return M
