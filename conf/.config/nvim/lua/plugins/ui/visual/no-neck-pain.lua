return {
  "shortcuts/no-neck-pain.nvim",
  config = function()
    require("no-neck-pain").setup({
      width = 170,
      autocmds = {
        enableOnVimEnter = "safe",
      },
      integrations = {
        -- nnpが自分でNvimTreeを再オープンする挙動を止める。
        -- これを有効のままにすると、NvimTreeOpen時にnnpが自分の再initを
        -- 同時に走らせ、その一瞬右サイドが無効になった隙に我々の
        -- toggle_side("left")が発火 → 「両サイド無効」判定 → nnp全体が
        -- disableされる、というカスケードで無効化される
        NvimTree = {
          position = "left",
          reopen = false,
        },
      },
    })

    vim.keymap.set("n", "<leader>zz", function()
      require("no-neck-pain").toggle()
    end, { desc = "Toggle NoNeckPain" })

    -- NvimTree展開中は左サイドバッファ（no-neck-pain-left）を閉じ、
    -- 非展開時は中央寄せのため復活させる。
    -- 画面が十分広いとno-neck-pain内蔵のNvimTree統合だけでは左サイドが残り、
    -- `NvimTree|空|main` の見た目になるため補正する
    --
    -- 発火源はnvim-tree公式のapi.events (TreeOpen/TreeClose)。
    -- FileType/BufWinLeaveと違い「本当に開いた/閉じた」瞬間だけ1回発火するため、
    -- Telescopeでの選択などで発生する複数BufEnterイベントに巻き込まれない。
    local function nvimtree_visible()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "NvimTree" then
          return true
        end
      end
      return false
    end

    -- trailing debounce: 最後の呼び出しから150ms経過したら1回だけ実行する
    -- nvim-treeが一時的に閉じて再オープンするようなケースで、
    -- 中間状態が走らないようにする
    --
    -- 公式APIの toggle_side は「両サイド無効なら nnp 全体を disable」
    -- という副作用を持つ。NvimTreeOpen 直後は nnp の右サイドが一時的に
    -- 無効化される瞬間があり、そこで toggle_side("left") が発火すると
    -- 「左を disable → 両サイド無効判定 → nnp 全体 disable」の連鎖で
    -- nnp が完全に無効化されるため、config 直接書き換え + main.init 経由で
    -- 副作用のない再構築を行う
    local pending_timer = nil
    local function schedule_sync(want_left_override)
      if pending_timer then
        pending_timer:stop()
        pending_timer:close()
        pending_timer = nil
      end
      pending_timer = vim.uv.new_timer()
      pending_timer:start(
        150,
        0,
        vim.schedule_wrap(function()
          if pending_timer then
            pending_timer:close()
            pending_timer = nil
          end
          if _G.NoNeckPain == nil or _G.NoNeckPain.config == nil then
            return
          end
          -- ユーザーが明示的に nnp を disable している場合は何もしない。
          -- 勝手に enable し直すと `<leader>zz` で切った意図に反する
          if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
            return
          end
          -- 起動直後 (`nvim .`) は NvimTree の window が nnp に「main
          -- (curr)」として登録されている壊れた状態になっており、そこで
          -- main.init を回すとレイアウトがさらに壊れる。
          -- nnp の curr が NvimTree バッファを指しているときだけ skip する。
          -- 通常の `:NvimTreeOpen` では focus は NvimTree にあるが、nnp の
          -- curr は元のファイル window のままなので、それはブロックしない
          local ok_probe, nnp_state_probe = pcall(require, "no-neck-pain.state")
          if ok_probe then
            local curr_id = nnp_state_probe:get_side_id("curr")
            if curr_id and vim.api.nvim_win_is_valid(curr_id) then
              local curr_buf = vim.api.nvim_win_get_buf(curr_id)
              if vim.bo[curr_buf].filetype == "NvimTree" then
                return
              end
            end
          end
          local want_left
          if want_left_override ~= nil then
            want_left = want_left_override
          else
            want_left = not nvimtree_visible()
          end
          local left_enabled = _G.NoNeckPain.config.buffers.left.enabled
          if want_left == left_enabled then
            return
          end
          local ok_state, nnp_state = pcall(require, "no-neck-pain.state")
          local ok_main, nnp_main = pcall(require, "no-neck-pain.main")
          if not (ok_state and ok_main) then
            return
          end
          -- config を false に切り替える前に、既存の左サイドウィンドウを
          -- 手動で閉じておく。main.init の close ロジックは
          -- `is_side_enabled_and_valid=true`（＝config.enabled=true）の
          -- ときしか動かないため、config を先に false にすると閉じ処理が
          -- スキップされて空バッファが残る
          if not want_left then
            local left_id = nnp_state:get_side_id("left")
            if left_id and vim.api.nvim_win_is_valid(left_id) then
              pcall(vim.api.nvim_win_close, left_id, true)
            end
            nnp_state:set_side_id(nil, "left")
          end
          _G.NoNeckPain.config.buffers.left.enabled = want_left
          pcall(function()
            nnp_state:scan_layout("sync_left_side")
            nnp_main.init("sync_left_side")
          end)
        end)
      )
    end

    -- nvim-tree公式イベントに購読する。プラグインロード順により
    -- nvim-tree.apiがまだない場合を考慮し、遅延しても購読を試みる
    local function attach_nvim_tree_events()
      local ok, nt_api = pcall(require, "nvim-tree.api")
      if not ok then
        return false
      end
      local Event = nt_api.events.Event
      nt_api.events.subscribe(Event.TreeOpen, function()
        schedule_sync(false) -- 開いた → 左サイド無効化を望む
      end)
      nt_api.events.subscribe(Event.TreeClose, function()
        schedule_sync(true) -- 閉じた → 左サイド有効化を望む
      end)
      return true
    end

    if not attach_nvim_tree_events() then
      -- nvim-treeが遅延ロードされている場合、コマンド実行時などにroやFileType経由で発火
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NvimTree",
        once = true,
        callback = function()
          vim.schedule(attach_nvim_tree_events)
        end,
      })
    end
  end,
}
