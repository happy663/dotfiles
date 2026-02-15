local M = {}

M.adapters = {
  http = {
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
        defaults = {
          -- opusplanは何故か選んでも機能しない
          -- model選択では表示されている
          -- interactionsの方で設定をすると機能するのかもしれない
          -- https://github.com/olimorris/codecompanion.nvim/discussions/2643
          model = "default",
        },
        env = {
          CLAUDE_CODE_OAUTH_TOKEN = function()
            return vim.fn.getenv("CLAUDE_CODE_OAUTH_TOKEN")
          end,
        },
      })
    end,
  },
}

M.interactions = {
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
      enabled = true,
    },
    callbacks = {
      ["on_ready"] = {
        actions = {
          "interactions.background.builtin.chat_make_title",
        },
        -- Enable "on_ready" callback which contains the title generation action
        enabled = true,
      },
    },
    keymaps = {
      clear = {
        modes = {
          n = { "gl" },
        },
      },
      stop = {
        modes = { n = "<C-c>" },
      },
    },
    -- smart-open.nvimを使用する/fileスラッシュコマンドのカスタマイズ
    slash_commands = {
      ["file"] = {
        callback = function(chat)
          -- smart-open.nvimでファイル選択（複数選択対応）
          require("telescope").extensions.smart_open.smart_open({
            attach_mappings = function()
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              actions.select_default:replace(function(bufnr)
                local picker = action_state.get_current_picker(bufnr)
                local selections = picker:get_multi_selection()

                -- 複数選択がなければ現在の選択を使用
                if vim.tbl_isempty(selections) then
                  selections = { action_state.get_selected_entry() }
                end

                actions.close(bufnr)

                -- SlashCommand.file の output メソッドを呼び出す
                local SlashCommand = require("codecompanion.interactions.chat.slash_commands.builtin.file")
                local cmd = SlashCommand.new({ Chat = chat })

                for _, selection in ipairs(selections) do
                  if selection then
                    cmd:output({
                      path = selection.path or selection.filename,
                      relative_path = selection.path and vim.fn.fnamemodify(selection.path, ":."),
                    })
                  end
                end
              end)
              return true
            end,
          })
        end,
        description = "Insert a file (smart-open)",
        opts = {
          contains_code = true,
          max_lines = 1000,
        },
      },
    },
  },
  inline = { adapter = "claude_code" },
  cmd = {
    adapter = "openai",
  },
  background = {
    adapter = {
      name = "copilot",
      model = "gpt-4o", -- 高速で安価なモデル
    },
    chat = {
      opts = {
        enabled = true, -- バックグラウンドチャット機能を有効化(タイトル生成に必要)
      },
    },
  },
}

return M
