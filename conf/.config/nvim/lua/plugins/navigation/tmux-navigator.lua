return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      -- デフォルトキーマップを無効化して手動で設定する
      vim.g.tmux_navigator_no_mappings = 1
    end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      -- "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
      -- { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
    config = function()
      -- Claude / Codex の TUI が開かれている terminal buffer かどうかを判定する。
      -- Lua pattern は | による OR をサポートしないため条件を2つに分けている。
      local function is_agent_terminal(bufnr)
        local name = vim.api.nvim_buf_get_name(bufnr)
        return vim.bo[bufnr].buftype == "terminal"
          and (name:match(":claude%f[%A]") ~= nil or name:match(":codex%f[%A]") ~= nil)
      end

      -- terminal job への control char 送信用。
      -- keymap で C-h/j/k/l を捕まえると TUI 側に届かなくなるため、
      -- 入力ありの場合は対応する ASCII バイトを job に直接送って補う。
      local control_chars = {
        h = "\008", -- BS (C-h)
        j = "\010", -- LF (C-j)
        k = "\011", -- VT (C-k)
        l = "\012", -- FF (C-l)
      }

      -- カーソル行を見て「TUI 側への実入力があるか」を返す。
      -- zsh の $BUFFER 相当を Neovim から直接取れないため、表示行をパースするヒューリスティック。
      local function get_current_terminal_input(bufnr)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""
        -- Claude TUI の入力欄はスペースに NBSP (U+00A0) を使うため正規化する
        local input = vim.trim(line:gsub("\xc2\xa0", " "))

        -- 罫線のみの行（水平セパレータ）はカーソルが乗っても入力なし扱いにする
        local border_only = input
        for _, char in ipairs({
          "─",
          "━",
          "═",
          "┌",
          "┐",
          "└",
          "┘",
          "├",
          "┤",
          "┬",
          "┴",
          "┼",
          "╭",
          "╮",
          "╰",
          "╯",
        }) do
          border_only = border_only:gsub(char, "")
        end

        if vim.trim(border_only) == "" then
          return ""
        end

        -- ボックス枠の縦線を両端から剥がして入力部分だけ残す
        for _, char in ipairs({ "│", "┃", "║" }) do
          input = vim.trim(input:gsub("^" .. char, ""):gsub(char .. "$", ""))
        end

        -- プロンプト記号の直後にカーソルがある場合はプレースホルダーとみなして空扱いにする。
        -- Claude,Codex のプレースホルダー文言は動的に変化するためカーソル位置で判定する。
        for _, prompt in ipairs({ ">", "›", "❯", "➜" }) do
          if vim.startswith(input, prompt) then
            local prompt_end = #prompt
            local after_prompt = input:sub(prompt_end + 1)
            local prompt_padding = after_prompt:match("^(%s*)") or ""

            if cursor[2] <= prompt_end + #prompt_padding then
              return ""
            else
              return vim.trim(after_prompt)
            end
          end
        end

        return input
      end

      local function send_control_char_to_terminal(bufnr, key)
        local job_id = vim.b[bufnr].terminal_job_id
        local control_char = control_chars[key]

        if job_id and control_char then
          vim.api.nvim_chan_send(job_id, control_char)
        end
      end

      -- terminal-job mode 専用のキーマップを設定する。
      -- 入力欄が空なら tmux/Neovim 間のペイン移動、入力中なら TUI へキーを転送する。
      local function set_terminal_tmux_navigate_keymap(bufnr, key, direction)
        vim.keymap.set("t", "<C-" .. key .. ">", function()
          local input = get_current_terminal_input(bufnr)

          if input == "" then
            vim.cmd("TmuxNavigate" .. direction)
          else
            send_control_char_to_terminal(bufnr, key)
          end
        end, {
          buffer = bufnr,
          silent = true,
          desc = "Tmux navigate " .. direction,
        })
      end

      local function set_agent_terminal_keymaps(bufnr)
        if not is_agent_terminal(bufnr) then
          return
        end

        set_terminal_tmux_navigate_keymap(bufnr, "h", "Left")
        set_terminal_tmux_navigate_keymap(bufnr, "j", "Down")
        set_terminal_tmux_navigate_keymap(bufnr, "k", "Up")
        set_terminal_tmux_navigate_keymap(bufnr, "l", "Right")
      end

      -- 新規 terminal buffer が開かれたときにキーマップを設定する
      vim.api.nvim_create_autocmd("TermOpen", {
        desc = "Use tmux navigator keys in agent terminals without sending text to the TUI",
        callback = function(event)
          set_agent_terminal_keymaps(event.buf)
        end,
      })

      -- プラグイン読み込み時点で既に開かれている terminal buffer にも適用する
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          set_agent_terminal_keymaps(bufnr)
        end
      end
    end,
  },
}
