return {
  {
    "folke/noice.nvim",
    cond = vim.g.not_in_vscode,
    -- 遅延ロード: 通知やコマンドライン使用時のみ
    event = { "VeryLazy" },
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          hover = {
            enabled = false,
          },
        },
        views = {
          my_float = {
            backend = "popup",
            relative = "editor",
            size = {
              width = "80%",
              height = 10,
            },
            position = {
              row = 100,
              col = 40,
            },
            border = {
              style = "rounded",
            },
          },
        },
        commands = {
          all = {
            view = "my_float", -- 独自ビュー名
            opts = {
              enter = true,
              format = "details",
            },
            filter = {},
          },
        },
        routes = {
          {
            filter = {
              event = "msg_show", -- msg_showイベントのメッセージを対象
              min_height = 1, -- 最小高さが1行のメッセージを対象
            },
            view = "mini",
          },
          {
            filter = {
              event = "notify",
              find = "No information available",
            },
            opts = { skip = true },
          },
          {
            filter = {
              event = "notify",
              find = "method textDocument/hover is not supported by any of the servers registered for the current buffer",
            },
            opts = { skip = true },
          },
          {
            filter = {
              event = "notify",
              find = "# Config Change Detected. Reloading...",
            },
          },
        },
        presets = {
          bottom_search = false,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      })

      local noice_visible = false
      local function toggle_noice()
        if noice_visible then
          vim.cmd("quit")
          noice_visible = false
        else
          vim.cmd("NoiceAll")
          noice_visible = true
        end
      end
      vim.keymap.set("n", "<C-.>", toggle_noice, {
        desc = "Toggle Noice",
        noremap = true,
        silent = true,
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
}
