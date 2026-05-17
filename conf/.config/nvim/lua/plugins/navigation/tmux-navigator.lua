return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
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
      local directions = {
        h = "Left",
        j = "Down",
        k = "Up",
        l = "Right",
      }

      local function is_agent_terminal(bufnr)
        local name = vim.api.nvim_buf_get_name(bufnr)
        -- review-comment:%f[%A]って何？
        return vim.bo[bufnr].buftype == "terminal" and name:match(":(claude|codex)%f[%A]") ~= nil
      end

      local function set_agent_terminal_keymaps(bufnr)
        if not is_agent_terminal(bufnr) then
          return
        end

        -- review-comment: for文使用しない方針の方が好きかな。関数定義してそれぞれ指定するとよさそう。10個ぐらいあるなら話は別だけど今回4個だし量が動的に増える訳でもない
        for key, direction in pairs(directions) do
          vim.keymap.set("t", "<C-" .. key .. ">", function()
            vim.cmd("TmuxNavigate" .. direction)
          end, {
            buffer = bufnr,
            silent = true,
            desc = "Tmux navigate " .. direction,
          })
        end
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        desc = "Use tmux navigator keys in agent terminals without sending text to the TUI",
        callback = function(event)
          set_agent_terminal_keymaps(event.buf)
        end,
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          set_agent_terminal_keymaps(bufnr)
        end
      end
    end,
  },
}
