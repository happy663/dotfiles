-- Firenvim 専用の最小 Neovim 設定
-- NVIM_APPNAME=firenvim-nvim で起動された時のみ読まれる

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

if vim.g.started_by_firenvim then
  vim.opt.laststatus = 0
  vim.opt.showtabline = 0
  vim.opt.cmdheight = 1
  vim.opt.signcolumn = "no"
  vim.opt.number = false
  vim.opt.relativenumber = false
end

require("lazy").setup({
  spec = {
    {
      "glacambre/firenvim",
      lazy = false,
      build = ":call firenvim#install(0)",
      init = function()
        if vim.g.started_by_firenvim then
          vim.opt.laststatus = 0
          vim.opt.showtabline = 0
          vim.opt.cmdheight = 1
        end
        vim.api.nvim_create_autocmd("UIEnter", {
          group = vim.api.nvim_create_augroup("FirenvimResize", { clear = true }),
          callback = function()
            local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
            if client and client.name == "Firenvim" and vim.o.lines < 20 then
              vim.o.lines = 20
            end
          end,
        })
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = "github.com_*.txt",
          command = "set filetype=markdown",
        })
        vim.g.firenvim_config = {
          localSettings = {
            [".*"] = {
              cmdline = "firenvim",
              content = "text",
              takeover = "never",
              priority = 0,
            },
          },
        }
      end,
    },
    -- { import = "plugins.ai" },
    -- { import = "plugins.colorschemas" },
    -- { import = "plugins.completion" },
    -- { import = "plugins.edit_support" },
    -- { import = "plugins.fuzzyfinder" },
    -- { import = "plugins.git" },
    { import = "plugins.japanese" },
    -- { import = "plugins.languages" },
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
