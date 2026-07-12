return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_browser = "Google Chrome"
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_theme = "dark"

      -- OctoPreview が opt-in 制御するためのブラウザオープン関数。
      -- 許可された shadow bufnr の URL だけ Chrome を起動して開く。
      -- vim.g.mkdp_allowed_bufnr に shadow bufnr をセットすると、その bufnr
      -- が URL に含まれる場合のみ Chrome を開く。
      -- mkdp サーバーは `plugin.nvim.call(browserfunc, [url])` で呼ぶため
      -- v:lua.* ではなく通常の Vimscript グローバル関数を用意する
      _G.__octo_preview_open_browser = function(url)
        local allowed = vim.g.mkdp_allowed_bufnr
        if not allowed or allowed == 0 then
          return
        end
        local url_bufnr = tonumber(url:match("/page/(%d+)"))
        if url_bufnr ~= allowed then
          return
        end
        vim.fn.jobstart({ "open", "-a", "Google Chrome", url }, { detach = true })
      end
      vim.cmd([[
        function! OctoPreviewOpenBrowser(url) abort
          call v:lua.__octo_preview_open_browser(a:url)
        endfunction
      ]])
      vim.g.mkdp_browserfunc = "OctoPreviewOpenBrowser"
    end,
    ft = { "markdown" },
  },
}
