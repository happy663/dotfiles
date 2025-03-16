return {
  {
    "akinsho/bufferline.nvim",
    dependencies = "kyazdani42/nvim-web-devicons",
    version = "*",
    cond = vim.g.not_in_vscode,
    config = function()
      local bufferline = require("bufferline")
      bufferline.setup({
        options = {
          numbers = "none",
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = false,
          diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          style_preset = bufferline.style_preset.no_italic,
        },
      })
      vim.api.nvim_set_keymap("n", "<leader>bco", ":BufferLineCloseOthers<CR>", { noremap = true, silent = true })
    end,
  },
}
