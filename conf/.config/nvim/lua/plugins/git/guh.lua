-- guh.nvim: minimal GitHub client for Neovim by justinmk
-- Requires Nvim 0.13+ and `gh` CLI. No config, one command: :Guh
return {
  {
    "justinmk/guh.nvim",
    lazy = true,
    cmd = { "Guh" },
    keys = {
      -- どこからでもカーソル下の PR番号 / URL / owner/repo#N を開く (README 推奨)
      { "Ug", "<cmd>Guh .<cr>", desc = "Guh: open target under cursor" },
    },
  },
}
