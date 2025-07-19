return {
  {
    "sindrets/diffview.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      { "<leader>dff", "<cmd>DiffviewOpen<CR>", desc = "DiffviewOpen" },
      { "<leader>dfq", "<cmd>DiffviewClose<CR>", desc = "DiffviewClose" },
    },
    config = function()
      vim.api.nvim_set_keymap("n", "<leader>dff", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<leader>dfq", "<cmd>DiffviewClose<CR>", { noremap = true, silent = true })
    end,
  },
}
