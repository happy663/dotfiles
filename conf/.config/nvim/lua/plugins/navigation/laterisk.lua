return {
  {
    "rapan931/lasterisk.nvim",
    config = function()
      vim.keymap.set("n", "*", function()
        -- hlslensを明示的に読み込み
        require("hlslens")

        local pos = vim.api.nvim_win_get_cursor(0)

        require("lasterisk").search()
        vim.cmd("set hlsearch")

        vim.api.nvim_win_set_cursor(0, pos)

        -- hlslensを起動
        vim.schedule(function()
          require("hlslens").start()
        end)

        vim.g.highlight_on = true
      end)

      vim.keymap.set({ "n", "x" }, "g*", function()
        require("hlslens")

        local pos = vim.api.nvim_win_get_cursor(0)

        require("lasterisk").search({ is_whole = false })
        vim.cmd("set hlsearch")

        vim.api.nvim_win_set_cursor(0, pos)

        vim.schedule(function()
          require("hlslens").start()
        end)

        vim.g.highlight_on = true
      end)
    end,
  },
}
