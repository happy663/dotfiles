return {
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- lazy = true,
    -- keys = {
    --   { "<leader>gn", desc = "Copy git link" },
    -- },
    config = function()
      require("gitlinker").setup({
        opts = {
          remote = nil, -- force the use of a specific remote
          -- adds current line nr in the url for normal mode
          add_current_line_on_normal_mode = true,
          -- callback for what to do with the url
          action_callback = require("gitlinker.actions").copy_to_clipboard,
          -- print the url after performing the action
          print_url = true,
        },
        callbacks = {
          ["github.com"] = require("gitlinker.hosts").get_github_type_url,
          ["gitlab.com"] = require("gitlinker.hosts").get_gitlab_type_url,
          ["try.gitea.io"] = require("gitlinker.hosts").get_gitea_type_url,
          ["codeberg.org"] = require("gitlinker.hosts").get_gitea_type_url,
          ["bitbucket.org"] = require("gitlinker.hosts").get_bitbucket_type_url,
          ["try.gogs.io"] = require("gitlinker.hosts").get_gogs_type_url,
          ["git.sr.ht"] = require("gitlinker.hosts").get_srht_type_url,
          ["git.launchpad.net"] = require("gitlinker.hosts").get_launchpad_type_url,
          ["repo.or.cz"] = require("gitlinker.hosts").get_repoorcz_type_url,
          ["git.kernel.org"] = require("gitlinker.hosts").get_cgit_type_url,
          ["git.savannah.gnu.org"] = require("gitlinker.hosts").get_cgit_type_url,
        },
        -- default mapping to call url generation with action_callback
        -- mappings = "<leader>gn",
      })

      vim.keymap.set(
        "n",
        "<leader>gn",
        ':lua require("gitlinker").get_buf_range_url("n")<CR>',
        { desc = "Copy git link" }
      )

      vim.keymap.set(
        "v",
        "<leader>gn",
        ':lua require("gitlinker").get_buf_range_url("v")<CR>',
        { desc = "Copy git link" }
      )

      local function get_visual_selection()
        --   -- これだと現在選択している所を取得できない、1つ前に選択した所を選択することになる
        --   -- local start_pos = vim.fn.getpos("'<")
        --   -- local start_pos = vim.fn.getpos("'>")
        --   -- 実装参考 https://github.com/ruifm/gitlinker.nvim/blob/cc59f732f3d043b626c8702cb725c82e54d35c25/lua/gitlinker/buffer.lua#L14-L14
        -- gitlinkerと同じ方法で取得
        local start_pos = vim.fn.getpos("v") -- visual開始位置
        local end_pos = vim.fn.getcurpos() -- 現在のカーソル位置

        -- 行番号を取得（start_pos[2]が行番号）
        local start_line = math.min(start_pos[2], end_pos[2])
        local end_line = math.max(start_pos[2], end_pos[2])

        -- 想定使用ケースはVで行ごとに選択なので行頭と行末を指定する
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

        if #lines == 0 then
          return ""
        end

        return table.concat(lines, "\n")
      end

      local function copy_gitlinker_with_snippet()
        local url = require("gitlinker").get_buf_range_url("v", { action_callback = nil })
        local snippet = get_visual_selection()
        if snippet == "" then
          print("No selection")
          return
        end
        local final_text = "```" .. vim.bo.filetype .. "\n" .. snippet .. "\n```" .. "\n\n" .. url
        vim.fn.setreg("+", final_text)
        print("Copied git link with code snippet to clipboard:")
      end

      vim.keymap.set("v", "<leader>gN", copy_gitlinker_with_snippet, { desc = "Copy git link with code snippet" })
    end,
  },
}
