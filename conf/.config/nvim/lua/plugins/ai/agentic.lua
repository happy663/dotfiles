return {
  "carlos-algms/agentic.nvim",
  -- dir = "~/src/github.com/carlos-algms/agentic.nvim",
  -- these are just suggested keymaps; customize as desired
  keys = {
    {
      "<C-;>",
      function()
        require("agentic").toggle()
      end,
      mode = { "n", "v", "i" },
      desc = "Toggle Agentic Chat",
    },
    {
      "<C-'>",
      function()
        require("agentic").add_selection_or_file_to_context()
      end,
      mode = { "n", "v" },
      desc = "Add file or selection to Agentic to Context",
    },
    {
      "<leader>agn",
      function()
        require("agentic").new_session()
      end,
      mode = { "n", "v" },
      desc = "New Agentic Session",
    },
    {
      "<leader>agr", -- ai Restore
      function()
        require("agentic").restore_session()
      end,
      desc = "Agentic Restore session",
      silent = true,
      mode = { "n", "v" },
    },
  },
  config = function()
    local agentic = require("agentic")

    agentic.setup({
      -- Available by default: "claude-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "auggie-acp"
      settings = {
        move_cursor_to_chat_on_submit = false, -- カーソルをプロンプトに留める
      },
      provider = "claude-acp", -- setting the name here is all you need to get started
      keymaps = {
        -- Keybindings for ALL buffers in the widget (chat, prompt, code, files)
        widget = {
          close = "q", -- String for a single keybinding
          -- FIX :-- ここのkey設定を行っても有効にならない
          change_mode = {
            {
              "<leader>am", -- Same as the global toggle, but also works inside the widget
              mode = { "n", "v" }, -- Specify modes for this keybinding
            },
          },
        },

        -- Keybindings for the prompt buffer only
        prompt = {
          submit = {
            "<CR>", -- Normal mode, just Enter
            {
              "<C-s>",
              mode = { "n", "v", "i" },
            },
          },

          paste_image = {
            {
              "<localLeader>p",
              mode = { "n" },
            },
            {
              "<C-v>", -- Same as Claude-code in insert mode
              mode = { "i" },
            },
          },
        },

        -- Keybindings for diff preview navigation
        diff_preview = {
          next_hunk = "]c",
          prev_hunk = "[c",
        },
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "AgenticChat",
      callback = function()
        vim.keymap.set("n", "<C-c>", function()
          agentic.stop_generation()
        end, { buffer = true, silent = true })
      end,
    })
  end,
}
