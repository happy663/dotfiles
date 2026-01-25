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
    version = "v18.5.0",
    keys = {
      -- { "<leader>ccc", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
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
              local success = chat.acp_connection:set_mode("plan")
              if success then
                -- モデルをopusplanに切り替え
                chat:change_model({ model = "opus" })
                vim.notify("Switched to plan mode (opus)", vim.log.levels.INFO, { title = "CodeCompanion" })
                chat:update_metadata()
              else
                vim.notify("Failed to switch mode", vim.log.levels.ERROR, { title = "CodeCompanion" })
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
              local success = chat.acp_connection:set_mode("default")
              if success then
                -- モデルをsonnetに切り替え
                chat:change_model({ model = "default" })
                vim.notify("Switched to default mode (sonnet)", vim.log.levels.INFO, { title = "CodeCompanion" })
                chat:update_metadata()
              else
                vim.notify("Failed to switch mode", vim.log.levels.ERROR, { title = "CodeCompanion" })
              end
            else
              vim.notify("ACP connection not available", vim.log.levels.WARN, { title = "CodeCompanion" })
            end
          end, { buffer = true, desc = "Switch to default mode" })

          -- モードトグルキーマップ
          vim.keymap.set("n", "<leader>mt", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local Chat = require("codecompanion.interactions.chat")
            local chat = Chat.buf_get_chat(bufnr)

            if chat and chat.acp_connection then
              local modes = chat.acp_connection:get_modes()
              if modes then
                local next_mode = (modes.currentModeId == "plan") and "default" or "plan"
                local next_model = (next_mode == "plan") and "opus" or "default"
                local success = chat.acp_connection:set_mode(next_mode)
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
                vim.notify("Modes not supported", vim.log.levels.WARN, { title = "CodeCompanion" })
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
        adapters = config.adapters,
        opts = {
          language = "Japanese",
          -- log_level = "DEBUG",
        },
        interactions = config.interactions,
        prompt_library = prompts.get(roles, short_names),
        extensions = {
          history = history.config,
        },
      })

      vim.g.codecompanion_auto_tool_mode = "true"

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

      -- Markdown保存用ヘルパー関数
      local function save_chat_as_markdown(chat)
        if not chat or not chat.opts or not chat.opts.save_id then
          return
        end

        local save_id = chat.opts.save_id
        local bufnr = chat.bufnr

        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        -- Markdownディレクトリの作成
        local md_dir = vim.fn.stdpath("data") .. "/codecompanion-history/markdown"
        vim.fn.mkdir(md_dir, "p")

        -- バッファの内容をそのまま取得
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- ファイルへの書き込み
        local md_path = md_dir .. "/" .. save_id .. "_" .. chat.opts.title .. ".md"
        local file = io.open(md_path, "w")
        if file then
          file:write(table.concat(lines, "\n"))
          file:close()
        end
      end
      -- チャット保存時にMarkdownファイルも保存
      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanion*Finished",
        callback = vim.schedule_wrap(function(opts)
          if opts.match == "CodeCompanionRequestFinished" or opts.match == "CodeCompanionToolsFinished" then
            if opts.match == "CodeCompanionRequestFinished" and opts.data.interaction ~= "chat" then
              return
            end
            local chat_module = require("codecompanion.interactions.chat")
            local bufnr = opts.data.bufnr
            if not bufnr then
              return
            end
            local chat = chat_module.buf_get_chat(bufnr)
            if chat then
              save_chat_as_markdown(chat)
            end
          end
        end),
      })
    end,
  },
}
