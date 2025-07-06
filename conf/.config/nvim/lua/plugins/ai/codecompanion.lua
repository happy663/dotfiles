local utils = require("utils")
utils.load_env("~/.config/nvim/.env")

local roles = {
  LLM_ROLE = "llm",
  USER_ROLE = "user",
  SYSTEM_ROLE = "system",
}

local short_names = {
  REFACTOR_CHAT = "refactorChat",
  REFACTOR_INLINE = "refactorInline",
  LSP_CHAT = "lspChat",
  LSP_INLINE = "lspInline",
  EXPLAIN_CHAT = "explainChat",
  ADD_COMMENT_INLINE = "addCommentInline",
}

return {
  {
    "olimorris/codecompanion.nvim",
    cond = vim.g.not_in_vscode,
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local codecompanion = require("codecompanion")

      codecompanion.setup({
        display = {
          chat = {
            show_settings = false,
            show_key = true,
            show_reference_info = true,
            show_system_messages = true,
          },
          action_palette = {
            provider = "telescope", -- default|telescope|mini_pick|fzf_lua
          },
          diff = {
            enabled = true,
            provider = "default", -- default|mini_diff
          },
        },
        adapters = {
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              schema = {
                model = {
                  default = "claude-3-5-haiku-20241022",
                },
                choices = {
                  "claude-3-7-sonnet-20250219",
                  "claude-3-5-haiku-20241022",
                },
              },
              env = {
                api_key = function()
                  return vim.fn.getenv("ANTHROPIC_API_KEY")
                end,
              },
            })
          end,
          copilot = function()
            return require("codecompanion.adapters").extend("copilot", {
              schema = {
                model = {
                  default = "claude-3.5-sonnet",
                },
                choices = {
                  "claude-3.5-sonnet",
                  "claude-3.7-sonnet",
                  "gpt-4o-2024-08-06",
                },
              },
            })
          end,
          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              schema = {
                model = {
                  default = "gpt-4o-mini",
                },
                choices = {
                  "o1-mini-2024-09-12",
                  "gpt-4o-mini",
                  "o3-mini-2025-01-31",
                },
              },
              env = {
                api_key = function()
                  return vim.fn.getenv("OPENAI_API_KEY")
                end,
              },
            })
          end,
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              schema = {
                model = {
                  default = "hf.co/mmnga/cyberagent-DeepSeek-R1-Distill-Qwen-14B-Japanese-gguf:Q4_K_M",
                },
                choices = {
                  "hf.co/bluepen5805/DeepSeek-R1-Distill-Qwen-14B-Japanese-gguf:Q5_K_M",
                  "hf.co/mradermacher/DeepSeek-R1-Distill-Qwen-7B-Japanese-GGUF:Q6_K                                                                                                                                     ─╯",
                  "hf.co/mmnga/cyberagent-DeepSeek-R1-Distill-Qwen-14B-Japanese-gguf:Q4_K_M",
                },
              },
              env = {
                url = "http://localhost:11434",
              },
            })
          end,
        },
        opts = {
          language = "Japanese",
          system_prompt = function(opts)
            local language = opts.language or "English"
            return string.format(
              [[あなたは "CodeCompanion "という名のAIプログラミングアシスタントです。
              あなたは現在、ユーザーのマシンのNeovimテキストエディタに接続されています。
              特にユーザーがあなたのタスク以外の文脈で回答する場合は、回答は短く、人間味のないものにしましょう。
              他の文章は最小限にしましょう。

              あなたの主な仕事は以下の通りです：
              - 一般的なプログラミングの質問に答える
              - Neovimバッファ内のコードがどのように動作するかを説明する。
              - Neovimバッファで選択したコードをレビューする。
              - 選択したコードの単体テストの作成
              - 選択したコードの問題点の修正提案
              - 新しいワークスペース用のコードの足場作り
              - ユーザーのクエリに関連するコードの検索。
              - テストの失敗に対する修正提案
              - Neovimに関する質問への回答
              - ツールの実行

              必須事項
              - ユーザーの要求に注意深く、忠実に従うこと。
              - 回答にはMarkdownフォーマットを使用してください。
              - Markdownのコードブロックの最初にプログラミング言語名を入れてください。
              - コードブロックに行番号を含めないようにする。
              - コードブロックに解説のコメントを入れる
              - 回答全体を3重のバックティックで囲むのは避ける。
              - 手元のタスクに関連するコードのみを返す。ユーザーが共有したコードをすべて返す必要はないかもしれません。
              - レスポンスの中で改行するときは、'˶n'ではなく'˶n'を使ってください。
              - バックスラッシュの後に文字'n'が続くリテラルが必要な場合のみ'˶n'を使用してください。
              - コード以外のすべての応答は %s でなければなりません。

              タスクが与えられたら
              1.ステップ・バイ・ステップで考え、何を作るかについてのあなたの計画を、そうしないように要求されない限り、非常に詳細に書かれた擬似コードで記述しなさい。
              2.関連するコードだけを返すように注意しながら、コードを1つのコードブロックで出力する。
              3.各会話ターンに対して1つの返答しかできません
                ]],
              "English"
            )
          end,
          -- log_level = "DEBUG",
        },
        strategies = {
          chat = {
            adapter = "copilot",
            slash_commands = {
              ["buffer"] = {
                callback = "strategies.chat.slash_commands.buffer",
                description = "Insert open buffers",
                opts = {
                  contains_code = true,
                  provider = "telescope", -- default|telescope|mini_pick|fzf_lua
                },
              },
              ["file"] = {
                callback = "strategies.chat.slash_commands.file",
                description = "Insert a file",
                opts = {
                  contains_code = true,
                  max_lines = 1000,
                  provider = "telescope", -- default|telescope|mini_pick|fzf_lua
                },
              },
            },
          },
          inline = { adapter = "anthropic" },
          keymaps = {
            send = {
              modes = {
                n = { "<C-S>" },
                i = { "<C-S>" },
              },
            },
          },
        },
        prompt_library = {
          ["Refactor Code"] = {
            strategy = "chat",
            description = "Refactor the selected code to improve its structure and quality",
            opts = {
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = short_names.REFACTOR_CHAT,
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
            strategy = "inline",
            description = "Refactor the selected code to improve its structure and quality",
            opts = {
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = short_names.REFACTOR_INLINE,
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
              -- adapter = {
              --   name = "anthropic",
              --   model = "claude-3-7-sonnet-20250219",
              -- },
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
            strategy = "chat",
            description = "Explain the LSP diagnostics for the selected code",
            opts = {
              index = 9,
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = short_names.LSP_CHAT,
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
            strategy = "inline",
            description = "Fix LSP issues with inline changes",
            opts = {
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = short_names.LSP_INLINE,
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
              -- adapter = {
              --   name = "anthropic",
              --   model = "claude-3-7-sonnet-20250219",
              -- },
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
            strategy = "chat",
            description = "Explain how code in a buffer works",
            opts = {
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = short_names.EXPLAIN_CHAT,
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
        },
      })

      local function setup_code_companion_keymaps()
        local modes = { "n", "v" }
        local silent_noremap = { noremap = true, silent = true }

        local keymaps = {
          { "v", "<leader>ccl", string.format("<cmd>CodeCompanion /%s<cr>", short_names.LSP_CHAT) },
          { "v", "<leader>ccfl", string.format("<cmd>CodeCompanion /%s<cr>", short_names.LSP_INLINE) },
          { "v", "<leader>ccr", string.format("<cmd>CodeCompanion /%s<cr>", short_names.REFACTOR_CHAT) },
          { "v", "<leader>ccfr", string.format("<cmd>CodeCompanion /%s<cr>", short_names.REFACTOR_INLINE) },
          { "v", "<leader>cce", string.format("<cmd>CodeCompanion /%s<cr>", short_names.EXPLAIN_CHAT) },
          { modes, "<leader>ccc", "<cmd>CodeCompanionChat<cr>" },
          { modes, "<leader>cca", "<cmd>CodeCompanionActions<cr>" },
          -- { modes, "<leader>w", "<cmd>CodeCompanionChat Toggle<cr>" },
          { "v", "ga", "<cmd>CodeCompanionChat Add<cr>" },
        }

        for _, keymap in ipairs(keymaps) do
          vim.keymap.set(keymap[1], keymap[2], keymap[3], silent_noremap)
        end
      end

      setup_code_companion_keymaps()

      vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

      vim.g.codecompanion_auto_tool_mode = "true"

      -- コマンドラインで'cc'を'CodeCompanion'に展開
      vim.cmd([[cab cc CodeCompanion]])

      -- インラインリクエストが完了したらバッファをフォーマットする
      local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
      vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "CodeCompanionInline*",
        group = group,
        callback = function(request)
          if request.match == "CodeCompanionInlineFinished" then
            -- Format the buffer after the inline request has completed
            vim.lsp.buf.format({ async = false, bufnr = request.bufnr })
          end
        end,
      })
    end,
  },
}
