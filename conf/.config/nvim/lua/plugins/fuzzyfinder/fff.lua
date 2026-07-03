return {
  {
    "dmtrKovalenko/fff.nvim",
    build = "cargo build --release",
    -- or if you are using nixos
    -- build = "nix run .#release",
    opts = {
      -- pass here all the options
    },
    keys = {
      {
        "<leader>tf", -- try it if you didn't it is a banger keybinding for a picker
        function()
          require("fff").find_files() -- or find_in_git_root() if you only want git files
        end,
        desc = "Open file picker",
      },
    },
    config = function()
      -- ローカルパッチ: Neovim 0.12ではenter=falseで開いたfloatに後から
      -- nvim_set_current_winでフォーカスを移せず、バッファを開いた状態だと
      -- ピッカーが操作不能になる（upstream未修正 @1cd8d31）。
      -- ui_creator読み込み前にenter=trueへ書き換える。:Lazy updateで
      -- ファイルが戻っても、次回ロード時にここで再適用される。
      local ui_creator = vim.fn.stdpath("data") .. "/lazy/fff.nvim/lua/fff/picker_ui/ui_creator.lua"
      if vim.fn.filereadable(ui_creator) == 1 then
        local lines = vim.fn.readfile(ui_creator)
        local changed = false
        local already_patched = false
        for i, line in ipairs(lines) do
          if line:find("nvim_open_win(S.input_buf, true,", 1, true) then
            already_patched = true
          end
          local patched, n = line:gsub("nvim_open_win%(S%.input_buf, false,", "nvim_open_win(S.input_buf, true,")
          if n > 0 then
            lines[i] = patched
            changed = true
          end
        end
        if changed then
          vim.fn.writefile(lines, ui_creator)
        elseif not already_patched then
          vim.notify(
            "fff.nvim: focusパッチの対象コードが見つかりません。upstreamの構造変更を確認してください",
            vim.log.levels.WARN
          )
        end
      end

      require("fff").setup({
        -- UI dimensions and appearance
        layout = {
          width = 0.8, -- Window width as fraction of screen
          height = 0.8, -- Window height as fraction of screen
          preview_size = 0.5, -- Preview width as fraction of picker
        },
        prompt = "🪿 ", -- Input prompt symbol
        preview = {
          enabled = true,
          max_lines = 100,
          max_size = 1024 * 1024, -- 1MB
        },
        title = "FFF Files", -- Window title
        max_results = 60, -- Maximum search results to display
        max_threads = 4, -- Maximum threads for fuzzy search

        keymaps = {
          close = "<C-c>",
          select = "<CR>",
          select_split = "<C-s>",
          select_vsplit = "<C-v>",
          select_tab = "<C-t>",
          -- Multiple bindings supported
          move_up = { "<Up>", "<C-p>" },
          move_down = { "<Down>", "<C-n>" },
          preview_scroll_up = "<C-u>",
          preview_scroll_down = "<C-d>",
        },

        -- Highlight groups
        hl = {
          border = "FloatBorder",
          normal = "Normal",
          cursor = "CursorLine",
          matched = "IncSearch",
          title = "Title",
          prompt = "Question",
          active_file = "Visual",
          frecency = "Number",
          debug = "Comment",
        },

        -- Debug options
        debug = {
          show_scores = false, -- Toggle with F2 or :FFFDebug
        },
      })
    end,
  },
}
