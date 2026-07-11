-- guh.nvim: minimal GitHub client for Neovim by justinmk
-- Requires Nvim 0.13+ and `gh` CLI. No config, one command: :Guh
return {
  {
    "justinmk/guh.nvim",
    lazy = true,
    cmd = { "Guh" },
  },
}
