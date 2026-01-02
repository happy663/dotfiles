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
  CHAT_WITH_BUFFER = "chatWithBuffer",
}

return {
  {
    "olimorris/codecompanion.nvim",
    cond = vim.g.not_in_vscode,
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    lazy = true,
    version = "v18.0.0",
    keys = {
      { "<leader>ccc", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
      { "<leader>cca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      { "<C-t>", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      {
        "<leader>ccl",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.LSP_CHAT),
        mode = "v",
        desc = "LSP Diagnostics Chat",
      },
      {
        "<leader>ccfl",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.LSP_INLINE),
        mode = "v",
        desc = "Fix LSP Inline",
      },
      {
        "<leader>ccr",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.REFACTOR_CHAT),
        mode = "v",
        desc = "Refactor Chat",
      },
      {
        "<leader>ccfr",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.REFACTOR_INLINE),
        mode = "v",
        desc = "Refactor Inline",
      },
      {
        "<leader>cce",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.EXPLAIN_CHAT),
        mode = "v",
        desc = "Explain Code",
      },
      { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add to Chat" },
      {
        "<leader>ccb",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.CHAT_WITH_BUFFER),
        mode = "n",
        desc = "Chat with Current Buffer",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local codecompanion = require("codecompanion")

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatCreated",
        callback = function()
          vim.notify("Welcome to CodeCompanion!", vim.log.levels.INFO, { title = "CodeCompanion" })
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

          for _, line in ipairs(lines) do
            if line:match("^#{buffer}$") then
              vim.cmd("normal! o")
              vim.cmd("normal! o")
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codecompanion",
        callback = function()
          vim.keymap.set("n", "gx", function()
            local url = vim.fn.expand("<cfile>")
            if url:match("^https?://") then
              vim.fn.jobstart({ "xdg-open", url }, { detach = true })
            else
              vim.notify("No valid URL under cursor", vim.log.levels.WARN, { title = "CodeCompanion" })
            end
          end, { buffer = true, silent = true })
        end,
      })

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
            provider = "split", -- inline|split|mini.diff
            provider_opts = {
              inline = {
                layout = "float", -- float|buffer - Where to display the diff
                opts = {
                  context_lines = 3, -- Number of context lines in hunks
                  dim = 25, -- Background dim level for floating diff (0-100, [100 full transparent], only applies when layout = "float")
                  full_width_removed = true, -- Make removed lines span full width
                  show_keymap_hints = true, -- Show "gda: accept | gdr: reject" hints above diff
                  show_removed = true, -- Show removed lines as virtual text
                },
              },
              split = {
                close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
                layout = "vertical", -- vertical|horizontal split
                opts = {
                  "internal",
                  "filler",
                  "closeoff",
                  "algorithm:histogram", -- https://adamj.eu/tech/2024/01/18/git-improve-diff-histogram/
                  "indent-heuristic", -- https://blog.k-nut.eu/better-git-diffs
                  "followwrap",
                  "linematch:120",
                },
              },
            },
          },
        },
        adapters = {
          http = {
            -- anthropic = function()
            --   return require("codecompanion.adapters").extend("anthropic", {
            --     schema = {
            --       model = {
            --         default = "claude-3-5-haiku-20241022",
            --       },
            --       choices = {
            --         "claude-3-7-sonnet-20250219",
            --         "claude-3-5-haiku-20241022",
            --       },
            --     },
            --     env = {
            --       api_key = function()
            --         -- return vim.fn.getenv("ANTHROPIC_API_KEY")
            --       end,
            --     },
            --   })
            -- end,
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
          acp = {
            claude_code = function()
              return require("codecompanion.adapters").extend("claude_code", {
                env = {
                  CLAUDE_CODE_OAUTH_TOKEN = function()
                    return vim.fn.getenv("CLAUDE_CODE_OAUTH_TOKEN")
                  end,
                },
              })
            end,
          },
        },
        opts = {
          language = "Japanese",
          -- log_level = "DEBUG",
        },
        interactions = {
          chat = {
            adapter = "claude_code",
            opts = {
              system_prompt = function(opts)
                local language = opts.language or "Japanese"
                return string.format(
                  [[
                  あなたは "CodeCompanion "という名のAIプログラミングアシスタントです。
                  あなたは現在、ユーザーのマシンのNeovimテキストエディタに接続されています。

                  必須事項
                  - 回答にはMarkdownフォーマットを使用してください。
                  - Markdownのコードブロックの最初にプログラミング言語名を入れてください。
                  - コードブロックに行番号を含めないようにする。
                  - コードブロックに解説のコメントを入れる
                  - 回答全体を3重のバックティックで囲むのは避ける。
                  - 手元のタスクに関連するコードのみを返す。ユーザーが共有したコードをすべて返す必要はないかもしれません。
                  - レスポンスの中で改行するときは、'˶n'ではなく'˶n'を使ってください。
                  - バックスラッシュの後に文字'n'が続くリテラルが必要な場合のみ'˶n'を使用してください。
                  - コード以外のすべての応答は %s でなければなりません。
                    ]],
                  "Japanese"
                )
              end,
            },
            keymaps = {
              -- send = {
              --   modes = {
              --     n = { "<C-S>" },
              --     i = { "<C-S>" },
              --   },
              -- },
              clear = {
                modes = {
                  n = { "<C-l>" },
                },
              },
            },
          },
          inline = { adapter = "claude_code" },
          cmd = {
            adapter = "openai",
          },
          -- background = {
          --   adapter = {
          --     name = "ollama",
          --     model = "qwen-7b-instruct",
          --   },
          -- },
        },
        prompt_library = {
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
        },
      })

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
