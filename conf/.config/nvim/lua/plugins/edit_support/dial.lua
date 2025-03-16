return {
  {
    "monaqa/dial.nvim",
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.constant.alias.bool, -- boolean value (true <-> false)
          augend.date.new({
            pattern = "%Y/%m/%d",
            default_kind = "day",
          }),
          augend.date.new({
            pattern = "%Y-%m-%d",
            default_kind = "day",
          }),
          augend.date.new({
            pattern = "%m/%d",
            default_kind = "day",
            only_valid = true,
          }),
          augend.date.new({
            pattern = "%H:%M",
            default_kind = "day",
            only_valid = true,
          }),
          augend.constant.alias.ja_weekday_full,
        },
      })

      vim.keymap.set("n", "<C-a>", function()
        require("dial.map").manipulate("increment", "normal")
      end)
      vim.keymap.set("n", "<C-x>", function()
        require("dial.map").manipulate("decrement", "normal")
      end)

      vim.keymap.set("n", "g<C-a>", function()
        require("dial.map").manipulate("increment", "gnormal")
      end)
      vim.keymap.set("n", "g<C-x>", function()
        require("dial.map").manipulate("decrement", "gnormal")
      end)
    end,
  },
}
