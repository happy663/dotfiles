return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local codecompanion = require("codecompanion")
      codecompanion.setup({
        prompt = {},
        display = {
          chat = {
            show_settings = true, -- cmpを使用する場合はtrueにする必要
          },
          action_palette = {
            provider = "telescope", -- default|telescope|mini_pick|fzf_lua
          },
        },
        adapters = {
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              schema = {
                model = {
                  default = "claude-3-5-haiku-20241022",
                },
              },
              env = {
                api_key = "",
              },
            })
          end,
          copilot = function()
            return require("codecompanion.adapters").extend("copilot", {
              schema = {
                model = {
                  default = "gpt-4o-2024-08-06",
                },
              },
            })
          end,
          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              schema = {
                model = {
                  default = "o1-mini-2024-09-12",
                },
              },
            })
          end,
        },
        opts = {
          language = "Japanese",
          ---@param adapter CodeCompanion.Adapter
          ---@return string
          -- system_prompt = function(adapter)
          --   print(adapter)
          --   if
          --     adapter.schema
          --     and adapter.schema.model
          --     and adapter.schema.model.default == "claude-3-5-haiku-20241022"
          --   then
          --     print("schemaが存在する")
          --     return "My custom system prompt"
          --   end
          --   print("schemaが存在しない")
          --   return "My default system prompt"
          -- end,
          log_level = "DEBUG",
        },
        strategies = {
          chat = {
            adapter = "anthropic",
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
                n = { "<C-S>" }, -- 送信を<C-s>のみに変更
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
              index = 12,
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = "refactor",
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[You are an expert in code refactoring. When refactoring code, follow these principles:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  1. Apply SOLID principles where appropriate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  2. Use design patterns effectively
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  3. Improve code modularity and reusability
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  4. Enhance readability and maintainability
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  5. Remove code duplication
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  6. Follow language-specific best practices
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  7. Preserve the original functionality
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  Return only the refactored code without explanations.]],
                opts = {
                  visible = false,
                },
              },
              {
                role = "user",
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
              index = 12,
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = "refactorfix",
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[You are an expert in code refactoring. When refactoring code, follow these principles:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      1. Apply SOLID principles where appropriate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      2. Use design patterns effectively
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      3. Improve code modularity and reusability
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      4. Enhance readability and maintainability
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      5. Remove code duplication
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      6. Follow language-specific best practices
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      7. Preserve the original functionality
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      Return only the refactored code without explanations.]],
                opts = {
                  visible = false,
                },
              },
              {
                role = "user",
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
          ["Fix LSP Inline"] = { -- 新しいプロンプト名
            strategy = "inline",
            description = "Fix LSP issues with inline changes",
            opts = {
              index = 11, -- 既存のプロンプトの後ろの番号を使用
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = "lspfix", -- 新しいショートネーム
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[You are an expert coder focusing on fixing LSP diagnostic issues. When fixing code:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          1. Only provide the corrected code
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          2. Ensure all LSP diagnostics are resolved
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          3. Maintain the original code style
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          4. Only include necessary changes
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5. Return raw code only without explanations or markdown]],
                opts = {
                  visible = false,
                },
              },
              {
                role = "user",
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
        },
      })

      vim.keymap.set({
        "n",
        "v",
      }, "<leader>ccfr", "<cmd>CodeCompanion /refactorfix<cr>", { noremap = true, silent = true })
      vim.keymap.set({
        "n",
        "v",
      }, "<leader>ccfl", "<cmd>CodeCompanion /lspfix<cr>", { noremap = true, silent = true })
      vim.keymap.set({
        "n",
        "v",
      }, "<leader>ccl", "<cmd>CodeCompanion /lsp<cr>", { noremap = true, silent = true })
      vim.keymap.set({ "n", "v" }, "<leader>ccr", "<cmd>CodeCompanion /refactor<cr>", { noremap = true, silent = true })

      vim.keymap.set("n", "<leader>ccc", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>ccc", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>ccff", "<cmd>CodeCompanion /fix<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>cce", "<cmd>CodeCompanion /explain<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>cce", "<cmd>CodeCompanion /explain<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>cca", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>cca", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>cct", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>cct", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
      -- 選択したチャットを現在のチャットバッファーに追加
      vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

      -- コマンドラインで'cc'を'CodeCompanion'に展開
      vim.cmd([[cab cc CodeCompanion]])
    end,
  },
}
