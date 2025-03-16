return {
  {
    "rapan931/lasterisk.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.keymap.set("n", "*", function()
        require("lasterisk").search()
        require("hlslens").start()
        vim.cmd("set hlsearch")
        vim.cmd("HlSearchLensEnable")
        vim.g.highlight_on = true
      end)
      vim.keymap.set({ "n", "x" }, "g*", function()
        require("lasterisk").search({ is_whole = false })
        require("hlslens").start()
        vim.cmd("set hlsearch")
        vim.cmd("HlSearchLensEnable")
        vim.g.highlight_on = true
      end)
    end,
  },
}
