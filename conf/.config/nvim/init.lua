vim.g.loaded_matchparen = 1
vim.g.mapleader = " "

-- 起動高速化
vim.loader.enable()

-- DOTFILES_DIR環境変数の設定（Ovimなどシェル経由でない起動時への対応）
if not vim.env.DOTFILES_DIR or vim.env.DOTFILES_DIR == "" then
  vim.env.DOTFILES_DIR = vim.fn.expand("$HOME") .. "/src/github.com/happy663/dotfiles"
end

-- 限定的なPATH環境でも必要なツールを認識できるようにする
local function ensure_path()
  local paths_to_add = {
    vim.fn.expand("$HOME") .. "/.nix-profile/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
  }

  local current_path = vim.env.PATH or ""
  for _, path in ipairs(paths_to_add) do
    -- パスが存在し、かつ現在のPATHに含まれていない場合のみ追加
    if vim.fn.isdirectory(path) == 1 and not string.find(current_path, path, 1, true) then
      vim.env.PATH = path .. ":" .. current_path
      current_path = vim.env.PATH
    end
  end
end

ensure_path()

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
    cache = {
      enabled = true,
      path = vim.fn.stdpath("cache") .. "/lazy",
      ttl = 86400, -- 24 hours
    },
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
    { import = "plugins.japanese" },
    { import = "plugins.languages" },
    { import = "plugins.misc" },
    { import = "plugins.navigation" },
    { import = "plugins.note" },
    { import = "plugins.terminal" },
    { import = "plugins.tools" },
    { import = "plugins.lsp" },
    { import = "plugins.highlight" },
    { import = "plugins.treesitter" },
    { import = "plugins.ui.explorer" },
    { import = "plugins.ui.statusline" },
    { import = "plugins.ui.visual" },
    { import = "plugins.ui.management" },
  },
})

if vim.g.not_in_vscode then
  require("core.auto-command")
  require("core.settings")
  require("core.keymaps")
  require("discord")
else
  require("self-vscode")
end

-- 必要になった戻す
if vim.fn.has("nvim") == 1 and vim.fn.executable("nvr") == 1 then
  vim.env.GIT_EDITOR = "nvr --remote-wait +'set bufhidden=wipe' +'normal! 7G' +'startinsert'"
end

-- Neovimサーバーソケットを起動（terminal_bridge用）
-- nvrからリモートでNeovimを制御するために必要
local socket_path = vim.fn.expand("$HOME/.cache/nvim/server.pipe")
local cache_dir = vim.fn.expand("$HOME/.cache/nvim")

-- キャッシュディレクトリが存在しない場合は作成
if vim.fn.isdirectory(cache_dir) == 0 then
  vim.fn.mkdir(cache_dir, "p")
end

-- サーバーが起動していない場合のみ起動
if vim.v.servername == "" or vim.v.servername == nil then
  local ok, err = pcall(vim.fn.serverstart, socket_path)
  if not ok then
    vim.notify("[init.lua] Failed to start server: " .. tostring(err), vim.log.levels.WARN)
  end
end
