return {
  {
    "fgheng/winbar.nvim",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("winbar").setup({
        enabled = true,
        show_file_path = true,
        show_symbols = true,
        colors = {
          path = "", -- You can customize colors like #c946fd
          file_name = "",
          symbols = "",
        },
        icons = {
          file_icon_default = "",
          seperator = ">",
          editor_state = "●",
          lock_icon = "",
        },
        exclude_filetype = {
          "help",
          "startify",
          "dashboard",
          "packer",
          "neogitstatus",
          "NvimTree",
          "Trouble",
          "alpha",
          "lir",
          "Outline",
          "spectre_panel",
          "toggleterm",
          "qf",
        },
      })

      -- Neovim 0.12: fff.nvim等の高さ1のfloating windowにwinbarが設定されると、
      -- 以後そのウィンドウに触れる処理がE36 (Not enough room) で失敗し
      -- ピッカーが操作不能になるため、floatではwinbarを設定しない
      local winbar_mod = require("winbar.winbar")
      local orig_show_winbar = winbar_mod.show_winbar
      winbar_mod.show_winbar = function(...)
        if vim.api.nvim_win_get_config(0).relative ~= "" then
          return
        end
        return orig_show_winbar(...)
      end
    end,
  },
}
