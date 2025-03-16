return {
  {
    "nvchad/showkeys",
    cond = vim.g.not_in_vscode,
    cmd = "ShowkeysToggle",
    opts = {
      timeout = 5,
      maxkeys = 5,
      -- more opts
    },
  },
}
