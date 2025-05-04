return {
  {
    "shougo/ddt.vim",
    cond = vim.g.not_in_vscode,
    config = function()
      -- ddt.vim の Lua 設定
      -- キーマッピング
      vim.keymap.set("n", "<Leader>dtt", function()
        vim.fn["ddt#start"]({
          name = "terminal-" .. vim.fn.win_getid(),
          ui = "terminal",
        })
      end, { desc = "Start ddt terminal" })

      vim.keymap.set("n", "<Leader>dts", function()
        vim.fn["ddt#start"]({
          name = "shell-" .. vim.fn.win_getid(),
          ui = "shell",
        })
      end, { desc = "Start ddt shell" })

      vim.keymap.set("n", "sD", function()
        vim.fn["ddt#ui#terminal#kill_editor"]()
      end, { desc = "Kill ddt editor" })

      -- denoの引数設定
      vim.g["denops#server#deno_args"] = {
        "-q",
        "-A",
        "--unstable-ffi",
      }

      -- ddt.vimのグローバル設定
      vim.fn["ddt#custom#patch_global"]({
        uiParams = {
          shell = {
            nvimServer = "~/.cache/nvim/server.pipe",
            prompt = "=\\>",
            promptPattern = "\\w*=\\> \\?",
          },
          terminal = {
            nvimServer = "~/.cache/nvim/server.pipe",
            command = { "bash" },
            promptPattern = vim.fn.has("win32") == 1 and "\\f\\+>" or "\\w*% \\?",
          },
        },
      })

      -- ddt-ui-shellのキーマッピング設定
      vim.api.nvim_create_augroup("ddt_shell", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = "ddt_shell",
        pattern = "ddt-shell",
        callback = function()
          -- ノーマルモードでのEnterキーマッピング
          vim.api.nvim_buf_set_keymap(
            0,
            "n",
            "<CR>",
            "<Cmd>call ddt#ui#do_action('executeLine')<CR>",
            { noremap = true, silent = true }
          )

          -- インサートモードでのEnterキーマッピング
          vim.api.nvim_buf_set_keymap(
            0,
            "i",
            "<CR>",
            "<Cmd>call ddt#ui#do_action('executeLine')<CR>",
            { noremap = true, silent = true }
          )
        end,
      })
    end,

    dependencies = {
      "shougo/ddt-ui-shell",
      "shougo/ddt-ui-terminal",
    },
  },
}
