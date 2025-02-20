vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Example for configuring Neovim to load user-installed installed Lua rocks:
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"

vim.g.not_in_vscode = vim.g.vscode == nil

require("lazy").setup({
  performance = {
    rtp = {
      disabled_plugins = {
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
      },
    },
  },
  ui = {
    border = "double",
  },
  spec = {
    -- { import = "plugins" },
    -- TODO:複数形なのか単数形なのか統一した方がよさそう
    { import = "plugins.ai" },
    { import = "plugins.colorschemas" },
    { import = "plugins.completion" },
    { import = "plugins.edit_support" },
    { import = "plugins.fuzzyfinder" },
    { import = "plugins.git" },
    { import = "plugins.highlight" },
    { import = "plugins.japanese" },
    { import = "plugins.languages" },
    { import = "plugins.lsp" },
    { import = "plugins.misc" },
    { import = "plugins.navigation" },
    { import = "plugins.note" },
    { import = "plugins.terminal" },
    { import = "plugins.tools" },
    { import = "plugins.treesitter" },
    { import = "plugins.ui" },
  },
})

if vim.g.not_in_vscode then
  require("core.auto-command")
  require("core.settings")
  require("core.keymaps")
  require("discord")
  require("livegrep-history")
else
  require("self-vscode")
end

if vim.fn.has("nvim") == 1 and vim.fn.executable("nvr") == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe' +'normal! 7G' +'startinsert'"
end
