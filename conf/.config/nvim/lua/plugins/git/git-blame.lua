return {
  "f-person/git-blame.nvim",
  -- load the plugin at startup
  event = "VeryLazy",
  -- Because of the keys part, you will be lazy loading this plugin.
  -- The plugin wil only load once one of the keys is used.
  -- If you want to load the plugin at startup, add something like event = "VeryLazy",
  -- or lazy = false. One of both options will work.
  config = function()
    vim.api.nvim_set_keymap("n", "<leader>gb", "<cmd>GitBlameToggle<CR>", { noremap = true, silent = true })
    -- Load the plugin with the provided options
    require("gitblame").setup({
      enabled = false, -- Enable the plugin
      message_template = " <summary> • <date> • <author> • <<sha>>", -- Customize the message template
      date_format = "%m-%d-%Y %H:%M:%S", -- Customize the date format
      virtual_text_column = 1, -- Set the virtual text start column
    })
  end,
}
