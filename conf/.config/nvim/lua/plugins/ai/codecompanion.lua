local utils = require("utils")
utils.load_env(vim.env.DOTFILES_DIR .. "/.env")

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
    -- dir = "~/src/github.com/olimorris/codecompanion.nvim",
    cond = vim.g.not_in_vscode,
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    lazy = true,
    keys = {
      -- { "<leader>ccc", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
      { "<leader>cca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      {
        "<C-t>",
        function()
          local codecompanion = require("codecompanion")
          local chat = codecompanion.last_chat()

          if chat and chat.ui:is_visible() then
            -- 既存チャットを非表示
            vim.g.codecompanion_saved_width = vim.api.nvim_win_get_width(chat.ui.winnr)
            vim.cmd("CodeCompanionChat Toggle")
          elseif chat then
            -- 非表示のチャットを再表示
            if vim.g.codecompanion_saved_width then
              codecompanion.toggle({ window_opts = { width = vim.g.codecompanion_saved_width } })
            else
              vim.cmd("CodeCompanionChat Toggle")
            end
          else
            -- 新規チャット作成時に#{buffer}を含める
            local config = require("codecompanion.config")
            local chat_opts = {
              messages = {
                {
                  role = config.constants.USER_ROLE,
                  content = "#{buffer}",
                  opts = { contains_code = true },
                },
              },
              auto_submit = false,
            }
            if vim.g.codecompanion_saved_width then
              chat_opts.window_opts = { width = vim.g.codecompanion_saved_width }
            end
            codecompanion.chat(chat_opts)
          end
        end,
        mode = { "n", "v" },
        desc = "CodeCompanion Toggle with Buffer",
      },
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
        "<leader>ccx",
        "<cmd>CodeCompanionChat adapter=codex<cr>",
        mode = { "n", "v" },
        desc = "CodeCompanion Codex Chat",
      },
      {
        "<leader>ccc",
        string.format("<cmd>CodeCompanion /%s<cr>", short_names.CHAT_WITH_BUFFER),
        mode = "n",
        desc = "Chat with Current Buffer",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
    },
    config = function()
      local codecompanion = require("codecompanion")

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatCreated",
        callback = function()
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
              local open_cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
              vim.fn.jobstart({ open_cmd, url }, { detach = true })
            else
              vim.notify("No valid URL under cursor", vim.log.levels.WARN, { title = "CodeCompanion" })
            end
          end, { buffer = true, silent = true })

          -- Plan mode切り替えキーマップ

          vim.keymap.set("n", "<leader>mp", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local Chat = require("codecompanion.interactions.chat")
            local chat = Chat.buf_get_chat(bufnr)

            if chat and chat.acp_connection then
              local mode_opt = nil
              for _, opt in ipairs(chat.acp_connection:get_config_options()) do
                if opt.category == "mode" then
                  mode_opt = opt
                  break
                end
              end
              if mode_opt then
                local success = chat.acp_connection:set_config_option(mode_opt.id, "plan")
                if success then
                  chat:change_model({ model = "opus" })
                  vim.notify("Switched to plan mode (opus)", vim.log.levels.INFO, { title = "CodeCompanion" })
                  chat:update_metadata()
                else
                  vim.notify("Failed to switch mode", vim.log.levels.ERROR, { title = "CodeCompanion" })
                end
              else
                vim.notify("Mode option not available", vim.log.levels.WARN, { title = "CodeCompanion" })
              end
            else
              vim.notify("ACP connection not available", vim.log.levels.WARN, { title = "CodeCompanion" })
            end
          end, { buffer = true, desc = "Switch to plan mode" })

          vim.keymap.set("n", "<leader>md", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local Chat = require("codecompanion.interactions.chat")
            local chat = Chat.buf_get_chat(bufnr)

            if chat and chat.acp_connection then
              local mode_opt = nil
              for _, opt in ipairs(chat.acp_connection:get_config_options()) do
                if opt.category == "mode" then
                  mode_opt = opt
                  break
                end
              end
              if mode_opt then
                local success = chat.acp_connection:set_config_option(mode_opt.id, "default")
                if success then
                  chat:change_model({ model = "default" })
                  vim.notify("Switched to default mode (sonnet)", vim.log.levels.INFO, { title = "CodeCompanion" })
                  chat:update_metadata()
                else
                  vim.notify("Failed to switch mode", vim.log.levels.ERROR, { title = "CodeCompanion" })
                end
              else
                vim.notify("Mode option not available", vim.log.levels.WARN, { title = "CodeCompanion" })
              end
            else
              vim.notify("ACP connection not available", vim.log.levels.WARN, { title = "CodeCompanion" })
            end
          end, { buffer = true, desc = "Switch to default mode" })

          -- Ctrl+Tabでモード選択UI
          vim.keymap.set("n", "<C-Tab>", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local Chat = require("codecompanion.interactions.chat")
            local chat = Chat.buf_get_chat(bufnr)

            if not chat or not chat.acp_connection then
              vim.notify("ACP connection not available", vim.log.levels.WARN, { title = "CodeCompanion" })
              return
            end

            -- acp_session_optionsスラッシュコマンドでモード選択
            local SlashCommand = require("codecompanion.interactions.chat.slash_commands.builtin.acp_session_options")
            local cmd = SlashCommand.new({
              Chat = chat,
              config = require("codecompanion.config"),
              context = {},
            })
            cmd:execute()
          end, { buffer = true, desc = "Select mode" })

          -- モードトグルキーマップ
          vim.keymap.set("n", "<leader>mt", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local Chat = require("codecompanion.interactions.chat")
            local chat = Chat.buf_get_chat(bufnr)

            if chat and chat.acp_connection then
              local mode_opt = nil
              for _, opt in ipairs(chat.acp_connection:get_config_options()) do
                if opt.category == "mode" then
                  mode_opt = opt
                  break
                end
              end
              if mode_opt then
                local next_mode = (mode_opt.currentValue == "plan") and "default" or "plan"
                local next_model = (next_mode == "plan") and "opus" or "default"
                local success = chat.acp_connection:set_config_option(mode_opt.id, next_mode)
                if success then
                  chat:change_model({ model = next_model })
                  vim.notify(
                    "Switched to " .. next_mode .. " mode (" .. next_model .. ")",
                    vim.log.levels.INFO,
                    { title = "CodeCompanion" }
                  )
                  chat:update_metadata()
                else
                  vim.notify("Failed to switch mode", vim.log.levels.ERROR, { title = "CodeCompanion" })
                end
              else
                vim.notify("Mode option not available", vim.log.levels.WARN, { title = "CodeCompanion" })
              end
            else
              vim.notify("ACP connection not available", vim.log.levels.WARN, { title = "CodeCompanion" })
            end
          end, { buffer = true, desc = "Toggle mode" })
        end,
      })

      local config = require("plugins.ai.codecompanion.config")
      local prompts = require("plugins.ai.codecompanion.prompts")
      local history = require("plugins.ai.codecompanion.history")

      codecompanion.setup({
        display = {
          chat = {
            show_settings = false,
            show_key = true,
            show_reference_info = true,
            show_system_messages = true,
            show_reasoning = false,
            acp = {
              max_title_length = 15, -- Maximum title length (nil = unlimited)
            },
            window = {
              layout = "vertical", -- vertical|horizontal|float
            },
          },
          action_palette = {
            provider = "telescope", -- default|telescope|mini_pick|fzf_lua
          },
          diff = {
            enabled = true,
            threshold_for_chat = 30, -- At or below this, always display the diff in the chat buffer
            window = {
              opts = {},
            },
            word_highlights = {
              additions = true,
              deletions = true,
            },
          },
        },
        adapters = config.adapters,
        opts = {
          language = "Japanese",
          -- log_level = "DEBUG",
        },
        rules = {
          default = {
           description = "Collection of common files for all projects",
            files = {
              ".clinerules",
              ".cursorrules",
              ".goosehints",
              ".rules",
              ".windsurfrules",
              ".github/copilot-instructions.md",
              -- AGENT.md, AGENTS.md, CLAUDE.md系はClaude Codeが内部で読み込むため除外
            },
            is_preset = true,
          },
        },
        interactions = config.interactions,
        prompt_library = prompts.get(roles, short_names),
        extensions = {
          history = history.config,
        },
      })

      vim.g.codecompanion_auto_tool_mode = "true"

      -- WinResizedイベントでCodeCompanionバッファの幅を保存
      vim.api.nvim_create_autocmd("WinResized", {
        callback = function()
          local windows = vim.v.event.windows
          for _, win in ipairs(windows) do
            if vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[buf].filetype
              if ft == "codecompanion" then
                vim.g.codecompanion_saved_width = vim.api.nvim_win_get_width(win)
              end
            end
          end
        end,
      })

      -- コマンドラインで'cc'を'CodeCompanion'に展開
      vim.cmd([[cab cc CodeCompanion]])

      -- -- インラインリクエストが完了したらバッファをフォーマットする
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
      -- Markdownファイルをlive_grepするキーマップ
      vim.keymap.set("n", "<leader>ccm", function()
        local md_dir = vim.fn.stdpath("data") .. "/codecompanion-history/markdown"
        require("telescope.builtin").live_grep({
          prompt_title = "CodeCompanion Chat History",
          cwd = md_dir,
          default_text = "",
        })
      end, { desc = "Search CodeCompanion Chat Markdown" })

      vim.keymap.set("n", "<leader>ccp", function()
        local md_dir = vim.fn.stdpath("data") .. "/codecompanion-history/markdown"
        require("telescope.builtin").find_files({
          prompt_title = "CodeCompanion Chat History",
          cwd = md_dir,
          default_text = "",
        })
      end, { desc = "Search CodeCompanion Chat Markdown" })
    end,
  },
}

