return {
  "WilliamHsieh/overlook.nvim",
  opts = {},
  -- Optional: set up common keybindings
  keys = {
    {
      "<leader>[d",
      function()
        require("overlook.api").peek_definition()
      end,
      desc = "Overlook: Peek definition",
    },
    {
      "<leader>[c",
      function()
        require("overlook.api").close_all()
      end,
      desc = "Overlook: Close all popup",
    },
    {
      "<leader>[u",
      function()
        require("overlook.api").restore_popup()
      end,
      desc = "Overlook: Restore popup",
    },
  },
}
