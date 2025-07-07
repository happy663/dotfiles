return {
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    -- config = function()
    --   local get_option = vim.filetype.get_option
    --   vim.filetype.get_option = function(filetype, option)
    --     return option == "commentstring" and require("ts_context_commentstring.internal").calculate_commentstring()
    --       or get_option(filetype, option)
    --   end
    -- end,
  },
}
