-- herdr の中で C-h/j/k/l をシームレスに移動するための nvim 側（issue #351）。
-- herdr 側のプラグイン（同じリポジトリ。scripts/herdr-plugins.sh で入れる）が、ペインごとの目印ファイル
-- （~/.cache/herdr/nvim-panes/<pane-id> に生きている PID）を見て、キーを nvim に渡すか herdr がペインを移るかを決める。
-- ここでは目印の管理だけを使う。キーの割り当ては tmux-navigator.lua が持つ（tmux と herdr の両方に対応）。
return {
  {
    "aimdevlee/herdr-nvim-nav",
    tag = "v1.0.0",
    lazy = false,
    cond = function()
      return vim.env.HERDR_ENV == "1"
    end,
    config = function()
      require("herdr-nvim-nav").setup({
        with_tmux = false,
        keymaps = { left = {}, down = {}, up = {}, right = {} },
      })
    end,
  },
}
