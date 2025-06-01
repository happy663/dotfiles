return {
  "kazhala/close-buffers.nvim",
  cond = vim.g.not_in_vscode,
  config = function()
    require("close_buffers").setup({
      filetype_ignore = {}, -- Filetype to ignore when running deletions
      file_glob_ignore = {}, -- File name glob pattern to ignore when running deletions (e.g. '*.md')
      file_regex_ignore = {}, -- File name regex pattern to ignore when running deletions (e.g. '.*[.]md')
      preserve_window_layout = { "this", "nameless" }, -- Types of deletion that should preserve the window layout
      next_buffer_cmd = nil, -- Custom function to retrieve the next buffer when preserving window layout
    })

    vim.keymap.set("n", "<leader>bco", ":BDelete other<CR>", {
      desc = "Close Other Buffers",
      noremap = true,
    })
  end,
}
