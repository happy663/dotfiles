return {
  "shortcuts/no-neck-pain.nvim",
  config = function()
    require("no-neck-pain").setup({
      width = 170,
      autocmds = {
        enableOnVimEnter = "safe",
      },
    })

    vim.keymap.set("n", "<leader>zz", function()
      require("no-neck-pain").toggle()
    end, { desc = "Toggle NoNeckPain" })

    -- NvimTree展開中は左サイドバッファ（no-neck-pain-left）を閉じ、
    -- 非展開時は中央寄せのため復活させる。
    -- 画面が十分広いとno-neck-pain内蔵のNvimTree統合だけでは左サイドが残り、
    -- `NvimTree|空|main` の見た目になるため補正する
    local function nvimtree_visible()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "NvimTree" then
          return true
        end
      end
      return false
    end

    local syncing = false
    local function sync_left_side()
      if syncing then
        return
      end
      if _G.NoNeckPain == nil or _G.NoNeckPain.state == nil then
        return
      end
      if not _G.NoNeckPain.state.enabled then
        return
      end
      local left_enabled = _G.NoNeckPain.config.buffers.left.enabled
      local want_left = not nvimtree_visible()
      if want_left == left_enabled then
        return
      end
      syncing = true
      require("no-neck-pain").toggle_side("left")
      vim.defer_fn(function()
        syncing = false
      end, 200)
    end

    -- NvimTreeが表示されたとき（FileType発火）と閉じられたとき（BufWinLeave）に同期
    local group = vim.api.nvim_create_augroup("NoNeckPainNvimTreeSync", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "NvimTree",
      callback = function()
        vim.schedule(sync_left_side)
      end,
    })
    vim.api.nvim_create_autocmd("BufWinLeave", {
      group = group,
      pattern = "NvimTree_*",
      callback = function()
        vim.schedule(sync_left_side)
      end,
    })
  end,
}
