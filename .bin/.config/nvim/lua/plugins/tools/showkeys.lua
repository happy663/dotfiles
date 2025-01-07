return {
  {
    "nvchad/showkeys",
    cond = vim.g.not_in_vscode,
    cmd = "ShowkeysToggle",
    opts = {
      timeout = 1,
      maxkeys = 5,
      -- more opts
    },
  },
}
