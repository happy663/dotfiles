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
    config = function()
      -- "-" (go_up) で prdiff/prcomments から pr に戻る際、
      -- 取り残される prcomments/prlogs ウィンドウも一緒に閉じる。
      -- guh.nvim 本体は「対象バッファをカレントウィンドウに開く」だけで
      -- 関連ウィンドウの後始末をしないため、ユーザー側で補う。
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "gitcommit", "markdown" },
        callback = function(args)
          local name = vim.api.nvim_buf_get_name(args.buf)
          if not name:match("^guh://") then
            return
          end
          vim.keymap.set("n", "-", function()
            -- prdiff ウィンドウを覚えておく
            local prdiff_win
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
              if ok and vim.api.nvim_buf_get_name(buf):match("guh://.*/prdiff/") then
                prdiff_win = win
              end
            end
            -- prcomments/prlogs ウィンドウを閉じる
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
              if ok then
                local n = vim.api.nvim_buf_get_name(buf)
                -- NOTE: Lua pattern には | (OR) がないので個別に match する
                if n:match("/prcomments/") or n:match("/prlogs/") then
                  pcall(vim.api.nvim_win_close, win, true)
                end
              end
            end
            -- prdiff にカーソルを置いて go_up (prdiff → pr)
            if prdiff_win and vim.api.nvim_win_is_valid(prdiff_win) then
              vim.api.nvim_set_current_win(prdiff_win)
            end
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>(guh-up)", true, true, true), "n", false)
          end, { buffer = args.buf, desc = "Guh: go up (close diff/comments)" })

          -- <C-y>: 現在の guh:// バッファの GitHub URL をクリップボードへコピー
          vim.keymap.set("n", "<C-y>", function()
            local url = require("guh.gh").get_url(0)
            if url then
              vim.fn.setreg("+", url)
              vim.notify("Copied: " .. url)
            else
              vim.notify("No URL for this buffer", vim.log.levels.WARN)
            end
          end, { buffer = args.buf, desc = "Guh: copy GitHub URL" })
        end,
      })
    end,
  },
}
