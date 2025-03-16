return {
  {
    "lervag/vimtex",
    cond = vim.g.not_in_vscode,
    lazy = false,
    tag = "v2.15",
    init = function()
      vim.g.vimtex_view_general_viewer = "zathura"
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },
}
