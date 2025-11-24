return {
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    lazy = false,
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = function()
      local actions = require("diffview.actions")
      require("diffview").setup({
        keymaps = {
          view = {
            { "n", "q", actions.close, { desc = "ヘルプメニューを閉じる" } },
          },
          file_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "ヘルプメニューを閉じる" } },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "ヘルプメニューを閉じる" } },
          },
        },
      })
      vim.keymap.set("n", "<leader>df", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory --follow %<cr>", { desc = "File history" })
      vim.keymap.set("n", "<leader>dl", "<Cmd>.DiffviewFileHistory --follow<CR>", { desc = "Line history" })

      local function get_default_branch_name()
        local res = vim.system({ "git", "rev-parse", "--verify", "main" }, { capture_output = true }):wait()
        return res.code == 0 and "main" or "master"
      end

      -- Diff against local master branch
      vim.keymap.set("n", "<leader>dm", function()
        vim.cmd("DiffviewOpen " .. get_default_branch_name())
      end, { desc = "Diff against master" })

      -- Diff against remote master branch
      vim.keymap.set("n", "<leader>dM", function()
        vim.cmd("DiffviewOpen HEAD..origin/" .. get_default_branch_name())
      end, { desc = "Diff against origin/master" })
    end,
  },
}
