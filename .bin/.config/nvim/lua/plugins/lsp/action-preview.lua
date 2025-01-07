return {
  {
    "aznhe21/actions-preview.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.keymap.set({ "v", "n" }, "<Leader>ca", require("actions-preview").code_actions, {
        noremap = true,
        silent = true,
        desc = "Code Actions",
      })
      local hl = require("actions-preview.highlight")
      require("actions-preview").setup({
        highlight_command = {
          hl.delta(),
        },
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "top",
            preview_cutoff = 20,
            preview_height = function(_, _, max_lines)
              return max_lines - 15
            end,
          },
        },
      })
    end,
  },
}
