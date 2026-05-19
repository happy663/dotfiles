-- Ovim 専用の最小 Neovim 設定
-- NVIM_APPNAME=ovim-nvim で起動された時のみ読まれる

vim.loader.enable()
vim.g.mapleader = " "
vim.g.not_in_vscode = vim.g.vscode == nil

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- メイン nvim の設定を rtp に追加する
-- lazy.nvim の { import = "plugins.xxx" } は nvim_get_runtime_file でディレクトリを探すため rtp が必要
-- メイン nvim に plugin/ や after/plugin/ がないため auto-loading の副作用はない
vim.opt.rtp:append(vim.fn.expand("~/.config/nvim"))

require("lazy").setup({
  spec = {
    { import = "plugins.japanese" },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
