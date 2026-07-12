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
      -- vim.g.mkdp_allowed_bufnr が正の bufnr にセットされている（=OctoPreview
      -- 起動中）ときは、その bufnr の URL だけ Chrome を開いて他は無視する。
      -- 未設定 or 0 のときは通常の :MarkdownPreview として動くよう素直に Chrome
      -- で開く（通常の markdown プレビュー用途にリグレッションさせない）。
      -- mkdp サーバーは `plugin.nvim.call(browserfunc, [url])` で呼ぶため
      -- v:lua.* ではなく通常の Vimscript グローバル関数を用意する
      _G.__octo_preview_open_browser = function(url)
        local allowed = vim.g.mkdp_allowed_bufnr
        if allowed and allowed ~= 0 then
          -- OctoPreview 中: shadow bufnr のみ許可
          local url_bufnr = tonumber(url:match("/page/(%d+)"))
          if url_bufnr ~= allowed then
            return
          end
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
