-- Ovim 専用の最小 Neovim 設定
-- NVIM_APPNAME=ovim-nvim で起動された時のみ読まれる

vim.g.mapleader = " "
vim.g.not_in_vscode = vim.g.vscode == nil

-- メイン nvim の設定を rtp に追加する
-- lazy.nvim の { import = "plugins.xxx" } は nvim_get_runtime_file でディレクトリを探すため rtp が必要
-- メイン nvim に plugin/ や after/plugin/ がないため auto-loading の副作用はない
local nvim_config = vim.fn.expand("~/.config/nvim")
vim.opt.rtp:append(nvim_config)

-- rtp:append だけでは vim.loader のキャッシュに反映されないため package.path に直接追加する
package.path = nvim_config .. "/lua/?.lua;" .. nvim_config .. "/lua/?/init.lua;" .. package.path
vim.loader.enable()

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

-- Ovim の一時ファイル編集時に <C-CR> で保存終了
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*/Library/Caches/ovim/*",
  callback = function()
    vim.keymap.set("i", "<C-CR>", function()
      vim.cmd("wq")
    end, { buffer = true, silent = true })
    vim.keymap.set("n", "<C-CR>", ":wq<CR>", { buffer = true, silent = true })
  end,
})

require("lazy").setup({
  spec = {
    { import = "plugins.japanese" },
    { import = "plugins.completion" },
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

require("core.keymaps")
require("core.settings")
