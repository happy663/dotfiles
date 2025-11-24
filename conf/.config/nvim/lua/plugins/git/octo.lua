return {
  {
    "pwntester/octo.nvim",
    lazy = true,
    cmd = { "Octo" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      -- OR 'ibhagwan/fzf-lua',
      -- OR 'folke/snacks.nvim',
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      -- 多分遅延ロードの影響のせいでloadされていない状態でキーを打つとエラーになるかも
      {
        "<leader>olh",
        "<cmd>Octo issue list assignee=happy663 states=OPEN<CR>",
        desc = "Open Octo issues assigned to happy663",
      },
      {
        "<leader>olc",
        "<cmd>Octo issue list assignee=happy663 states=CLOSED<CR>",
        desc = "Open Octo issues assigned to happy663",
      },
      { "<leader>oll", "<cmd>Octo issue list<CR>", desc = "Open Octo issues" },
      { "<leader>oic", "<cmd>Octo issue create<CR>", desc = "Create a new Octo issue" },
    },
    config = function()
      require("octo").setup({
        use_local_fs = false, -- use local files on right side of reviews
        enable_builtin = false, -- shows a list of builtin actions when no action is provided
        default_remote = { "upstream", "origin" }, -- order to try remotes
        default_merge_method = "commit", -- default merge method which should be used for both `Octo pr merge` and merging from picker, could be `commit`, `rebase` or `squash`
        default_delete_branch = false, -- whether to delete branch when merging pull request with either `Octo pr merge` or from picker (can be overridden with `delete`/`nodelete` argument to `Octo pr merge`)
        ssh_aliases = {}, -- SSH aliases. e.g. `ssh_aliases = {["github.com-work"] = "github.com"}`. The key part will be interpreted as an anchored Lua pattern.
        picker = "telescope", -- or "fzf-lua" or "snacks"
        picker_config = {
          use_emojis = false, -- only used by "fzf-lua" picker for now
          mappings = { -- mappings for the pickers
            open_in_browser = { lhs = "<leader>ob", desc = "open issue in browser" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
            checkout_pr = { lhs = "<C-o>", desc = "checkout pull request" },
            merge_pr = { lhs = "<C-r>", desc = "merge pull request" },
          },
          snacks = { -- snacks specific config
            actions = { -- custom actions for specific snacks pickers (array of tables)
              issues = { -- actions for the issues picker
                -- { name = "my_issue_action", fn = function(picker, item) print("Issue action:", vim.inspect(item)) end, lhs = "<leader>a", desc = "My custom issue action" },
              },
              pull_requests = { -- actions for the pull requests picker
                -- { name = "my_pr_action", fn = function(picker, item) print("PR action:", vim.inspect(item)) end, lhs = "<leader>b", desc = "My custom PR action" },
              },
              notifications = {}, -- actions for the notifications picker
              issue_templates = {}, -- actions for the issue templates picker
              search = {}, -- actions for the search picker
              -- ... add actions for other pickers as needed
            },
          },
        },
        comment_icon = "▎", -- comment marker
        outdated_icon = "󰅒 ", -- outdated indicator
        resolved_icon = " ", -- resolved indicator
        reaction_viewer_hint_icon = " ", -- marker for user reactions
        commands = {}, -- additional subcommands made available to `Octo` command
        users = "search", -- Users for assignees or reviewers. Values: "search" | "mentionable" | "assignable"
        user_icon = " ", -- user icon
        ghost_icon = "󰊠 ", -- ghost icon
        timeline_marker = " ", -- timeline marker
        timeline_indent = 0, -- timeline indentation
        use_timeline_icons = true, -- toggle timeline icons
        timeline_icons = { -- the default icons based on timelineItems
          commit = "  ",
          label = "  ",
          reference = " ",
          connected = "  ",
          subissue = "  ",
          cross_reference = "  ",
          parent_issue = "  ",
          pinned = "  ",
          milestone = "  ",
          renamed = "  ",
          merged = { "  ", "OctoPurple" },
          closed = {
            closed = { "  ", "OctoRed" },
            completed = { "  ", "OctoPurple" },
            not_planned = { "  ", "OctoGrey" },
            duplicate = { "  ", "OctoGrey" },
          },
          reopened = { "  ", "OctoGreen" },
          assigned = "  ",
          review_requested = "  ",
        },
        right_bubble_delimiter = "", -- bubble delimiter
        left_bubble_delimiter = "", -- bubble delimiter
        github_hostname = "", -- GitHub Enterprise host
        snippet_context_lines = 4, -- number or lines around commented lines
        gh_cmd = "gh", -- Command to use when calling Github CLI
        gh_env = {}, -- extra environment variables to pass on to GitHub CLI, can be a table or function returning a table
        timeout = 5000, -- timeout for requests between the remote server
        default_to_projects_v2 = false, -- use projects v2 for the `Octo card ...` command by default. Both legacy and v2 commands are available under `Octo cardlegacy ...` and `Octo cardv2 ...` respectively.
        ui = {
          use_signcolumn = false, -- show "modified" marks on the sign column
          use_signstatus = true, -- show "modified" marks on the status column
        },
        issues = {
          order_by = { -- criteria to sort results of `Octo issue list`
            field = "CREATED_AT", -- either COMMENTS, CREATED_AT or UPDATED_AT (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
            direction = "DESC", -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
          },
        },
        reviews = {
          auto_show_threads = true, -- automatically show comment threads on cursor move
          focus = "right", -- focus right buffer on diff open
        },
        runs = {
          icons = {
            pending = "🕖",
            in_progress = "🔄",
            failed = "❌",
            succeeded = "",
            skipped = "⏩",
            cancelled = "✖",
          },
        },
        pull_requests = {
          order_by = { -- criteria to sort the results of `Octo pr list`
            field = "CREATED_AT", -- either COMMENTS, CREATED_AT or UPDATED_AT (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
            direction = "DESC", -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
          },
          always_select_remote_on_create = false, -- always give prompt to select base remote repo when creating PRs
          use_branch_name_as_title = false, -- sets branch name to be the name for the PR
        },
        notifications = {
          current_repo_only = false, -- show notifications for current repo only
        },
        file_panel = {
          size = 10, -- changed files panel rows
          use_icons = true, -- use web-devicons in file panel (if false, nvim-web-devicons does not need to be installed)
        },
        colors = { -- used for highlight groups (see Colors section below)
          white = "#ffffff",
          grey = "#2A354C",
          black = "#000000",
          red = "#fdb8c0",
          dark_red = "#da3633",
          green = "#acf2bd",
          dark_green = "#238636",
          yellow = "#d3c846",
          dark_yellow = "#735c0f",
          blue = "#58A6FF",
          dark_blue = "#0366d6",
          purple = "#6f42c1",
        },
        mappings_disable_default = true, -- disable default mappings if true, but will still adapt user mappings
        mappings = {
          runs = {
            expand_step = { lhs = "o", desc = "expand workflow step" },
            open_in_browser = { lhs = "<leader>ob", desc = "open workflow run in browser" },
            refresh = { lhs = "<C-r>", desc = "refresh workflow" },
            rerun = { lhs = "<C-o>", desc = "rerun workflow" },
            rerun_failed = { lhs = "<C-f>", desc = "rerun failed workflow" },
            cancel = { lhs = "<C-x>", desc = "cancel workflow" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
          },
          issue = {
            close_issue = { lhs = "<localleader>ic", desc = "close issue" },
            reopen_issue = { lhs = "<localleader>io", desc = "reopen issue" },
            list_issues = { lhs = "<localleader>il", desc = "list open issues on same repo" },
            reload = { lhs = "<C-r>", desc = "reload issue" },
            open_in_browser = { lhs = "<leader>ob", desc = "open issue in browser" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
            add_assignee = { lhs = "<localleader>aa", desc = "add assignee" },
            remove_assignee = { lhs = "<localleader>ad", desc = "remove assignee" },
            create_label = { lhs = "<localleader>lc", desc = "create label" },
            add_label = { lhs = "<localleader>la", desc = "add label" },
            remove_label = { lhs = "<localleader>ld", desc = "remove label" },
            goto_issue = { lhs = "<localleader>gi", desc = "navigate to a local repo issue" },
            add_comment = { lhs = "<leader>oa", desc = "add comment" },
            delete_comment = { lhs = "<localleader>cd", desc = "delete comment" },
            next_comment = { lhs = "]c", desc = "go to next comment" },
            prev_comment = { lhs = "[c", desc = "go to previous comment" },
            react_hooray = { lhs = "<localleader>rp", desc = "add/remove 🎉 reaction" },
            react_heart = { lhs = "<localleader>rh", desc = "add/remove ❤️ reaction" },
            react_eyes = { lhs = "<localleader>re", desc = "add/remove 👀 reaction" },
            react_thumbs_up = { lhs = "<localleader>r+", desc = "add/remove 👍 reaction" },
            react_thumbs_down = { lhs = "<localleader>r-", desc = "add/remove 👎 reaction" },
            react_rocket = { lhs = "<localleader>rr", desc = "add/remove 🚀 reaction" },
            react_laugh = { lhs = "<localleader>rl", desc = "add/remove 😄 reaction" },
            react_confused = { lhs = "<localleader>rc", desc = "add/remove 😕 reaction" },
          },
          pull_request = {
            checkout_pr = { lhs = "<localleader>po", desc = "checkout PR" },
            merge_pr = { lhs = "<localleader>pm", desc = "merge commit PR" },
            squash_and_merge_pr = { lhs = "<localleader>psm", desc = "squash and merge PR" },
            rebase_and_merge_pr = { lhs = "<localleader>prm", desc = "rebase and merge PR" },
            list_commits = { lhs = "<localleader>pc", desc = "list PR commits" },
            list_changed_files = { lhs = "<localleader>pf", desc = "list PR changed files" },
            show_pr_diff = { lhs = "<localleader>pd", desc = "show PR diff" },
            add_reviewer = { lhs = "<localleader>va", desc = "add reviewer" },
            remove_reviewer = { lhs = "<localleader>vd", desc = "remove reviewer request" },
            close_issue = { lhs = "<localleader>ic", desc = "close PR" },
            reopen_issue = { lhs = "<localleader>io", desc = "reopen PR" },
            list_issues = { lhs = "<localleader>il", desc = "list open issues on same repo" },
            reload = { lhs = "<C-r>", desc = "reload PR" },
            open_in_browser = { lhs = "<leader>ob", desc = "open PR in browser" },
            copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
            goto_file = { lhs = "gf", desc = "go to file" },
            add_assignee = { lhs = "<localleader>aa", desc = "add assignee" },
            remove_assignee = { lhs = "<localleader>ad", desc = "remove assignee" },
            create_label = { lhs = "<localleader>lc", desc = "create label" },
            add_label = { lhs = "<localleader>la", desc = "add label" },
            remove_label = { lhs = "<localleader>ld", desc = "remove label" },
            goto_issue = { lhs = "<localleader>gi", desc = "navigate to a local repo issue" },
            add_comment = { lhs = "<leader>oa", desc = "add comment" },
            delete_comment = { lhs = "<localleader>cd", desc = "delete comment" },
            next_comment = { lhs = "]c", desc = "go to next comment" },
            prev_comment = { lhs = "[c", desc = "go to previous comment" },
            react_hooray = { lhs = "<localleader>rp", desc = "add/remove 🎉 reaction" },
            react_heart = { lhs = "<localleader>rh", desc = "add/remove ❤️ reaction" },
            react_eyes = { lhs = "<localleader>re", desc = "add/remove 👀 reaction" },
            react_thumbs_up = { lhs = "<localleader>r+", desc = "add/remove 👍 reaction" },
            react_thumbs_down = { lhs = "<localleader>r-", desc = "add/remove 👎 reaction" },
            react_rocket = { lhs = "<localleader>rr", desc = "add/remove 🚀 reaction" },
            react_laugh = { lhs = "<localleader>rl", desc = "add/remove 😄 reaction" },
            react_confused = { lhs = "<localleader>rc", desc = "add/remove 😕 reaction" },
            review_start = { lhs = "<localleader>vs", desc = "start a review for the current PR" },
            review_resume = { lhs = "<localleader>vr", desc = "resume a pending review for the current PR" },
            resolve_thread = { lhs = "<localleader>rt", desc = "resolve PR thread" },
            unresolve_thread = { lhs = "<localleader>rT", desc = "unresolve PR thread" },
          },
          review_thread = {
            goto_issue = { lhs = "<localleader>gi", desc = "navigate to a local repo issue" },
            add_comment = { lhs = "<localleader>ca", desc = "add comment" },
            add_suggestion = { lhs = "<localleader>sa", desc = "add suggestion" },
            delete_comment = { lhs = "<localleader>cd", desc = "delete comment" },
            next_comment = { lhs = "]c", desc = "go to next comment" },
            prev_comment = { lhs = "[c", desc = "go to previous comment" },
            select_next_entry = { lhs = "]q", desc = "move to next changed file" },
            select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
            select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
            select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
            react_hooray = { lhs = "<localleader>rp", desc = "add/remove 🎉 reaction" },
            react_heart = { lhs = "<localleader>rh", desc = "add/remove ❤️ reaction" },
            react_eyes = { lhs = "<localleader>re", desc = "add/remove 👀 reaction" },
            react_thumbs_up = { lhs = "<localleader>r+", desc = "add/remove 👍 reaction" },
            react_thumbs_down = { lhs = "<localleader>r-", desc = "add/remove 👎 reaction" },
            react_rocket = { lhs = "<localleader>rr", desc = "add/remove 🚀 reaction" },
            react_laugh = { lhs = "<localleader>rl", desc = "add/remove 😄 reaction" },
            react_confused = { lhs = "<localleader>rc", desc = "add/remove 😕 reaction" },
            resolve_thread = { lhs = "<localleader>rt", desc = "resolve PR thread" },
            unresolve_thread = { lhs = "<localleader>rT", desc = "unresolve PR thread" },
          },
          submit_win = {
            approve_review = { lhs = "<C-a>", desc = "approve review", mode = { "n", "i" } },
            comment_review = { lhs = "<C-m>", desc = "comment review", mode = { "n", "i" } },
            request_changes = { lhs = "<C-r>", desc = "request changes review", mode = { "n", "i" } },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab", mode = { "n", "i" } },
          },
          review_diff = {
            submit_review = { lhs = "<localleader>vs", desc = "submit review" },
            discard_review = { lhs = "<localleader>vd", desc = "discard review" },
            add_review_comment = { lhs = "<localleader>ca", desc = "add a new review comment", mode = { "n", "x" } },
            add_review_suggestion = {
              lhs = "<localleader>sa",
              desc = "add a new review suggestion",
              mode = { "n", "x" },
            },
            focus_files = { lhs = "<localleader>e", desc = "move focus to changed file panel" },
            toggle_files = { lhs = "<localleader>b", desc = "hide/show changed files panel" },
            next_thread = { lhs = "]t", desc = "move to next thread" },
            prev_thread = { lhs = "[t", desc = "move to previous thread" },
            select_next_entry = { lhs = "]q", desc = "move to next changed file" },
            select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
            select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
            select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
            toggle_viewed = { lhs = "<localleader><space>", desc = "toggle viewer viewed state" },
            goto_file = { lhs = "gf", desc = "go to file" },
          },
          file_panel = {
            submit_review = { lhs = "<localleader>vs", desc = "submit review" },
            discard_review = { lhs = "<localleader>vd", desc = "discard review" },
            next_entry = { lhs = "j", desc = "move to next changed file" },
            prev_entry = { lhs = "k", desc = "move to previous changed file" },
            select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
            refresh_files = { lhs = "R", desc = "refresh changed files panel" },
            focus_files = { lhs = "<localleader>e", desc = "move focus to changed file panel" },
            toggle_files = { lhs = "<localleader>b", desc = "hide/show changed files panel" },
            select_next_entry = { lhs = "]q", desc = "move to next changed file" },
            select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
            select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
            select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
            close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
            toggle_viewed = { lhs = "<localleader><space>", desc = "toggle viewer viewed state" },
          },
          notification = {
            read = { lhs = "<localleader>nr", desc = "mark notification as read" },
            done = { lhs = "<localleader>nd", desc = "mark notification as done" },
            unsubscribe = { lhs = "<localleader>nu", desc = "unsubscribe from notifications" },
          },
        },
      })

      -- issueバッファ名のカスタマイズ: 番号の代わりにissueタイトルを使用
      -- UTF-8対応の安全な文字列処理を実装
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        pattern = "octo://*",
        callback = function(event)
          local bufname = vim.api.nvim_buf_get_name(event.buf)

          -- 既に処理済みかチェック
          if vim.b[event.buf].octo_title_processed then
            return
          end

          -- バッファ名からリポジトリ、種類、番号を抽出
          local repo, kind, number = bufname:match("octo://([^/]+/[^/]+)/([^/]+)/([^/]+)")

          if repo and kind == "issue" and number and tonumber(number) then
            -- UTF-8対応の安全な文字列切り取り関数
            local function utf8_safe_truncate(str, max_chars)
              local chars = {}
              -- UTF-8文字をパターンマッチングで1文字ずつ抽出
              for char in str:gmatch("([^\128-\191][\128-\191]*)") do
                table.insert(chars, char)
                if #chars >= max_chars then
                  break
                end
              end
              return table.concat(chars)
            end

            -- バッファコンテンツの読み込み待機と再試行
            local function try_extract_title(attempt)
              attempt = attempt or 1
              local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)

              if #lines <= 1 or (#lines == 1 and lines[1] == "") then
                if attempt < 10 then
                  vim.defer_fn(function()
                    try_extract_title(attempt + 1)
                  end, 100 * attempt)
                  return
                end
                return
              end

              -- issueタイトルを抽出
              local title = nil
              for _, line in ipairs(lines) do
                if line:match("^%s*[^#%s]") then
                  title = line:gsub("^%s+", ""):gsub("%s+$", "")
                  break
                end
              end

              if title and title ~= "" then
                -- ファイルシステム禁止文字のみ置換、日本語は保持
                local clean_title = title:gsub('[/\\:*?"<>|]', "_")
                clean_title = clean_title:gsub("%s+", "_")
                clean_title = clean_title:gsub("_+", "_")
                clean_title = clean_title:gsub("^[_%s]+", "")
                clean_title = clean_title:gsub("[_%s]+$", "")

                -- UTF-8対応の安全な長さ制限
                local max_chars = 30
                if vim.fn.strchars(clean_title) > max_chars then
                  clean_title = utf8_safe_truncate(clean_title, max_chars - 3) .. "..."
                end

                -- Copilot対応: LSPクライアントを一時的にデタッチ
                -- RPC[Error] code_name = InvalidParams, message = "Document for URI could not be found:
                local lsp_clients = vim.lsp.get_clients({ bufnr = event.buf })
                local client_ids = {}
                for _, client in ipairs(lsp_clients) do
                  table.insert(client_ids, client.id)
                  vim.lsp.buf_detach_client(event.buf, client.id)
                end

                -- バッファ名を変更（エラーハンドリング付き）
                local new_bufname = string.format("octo://%s/%s/%s", repo, kind, clean_title)
                local ok = pcall(vim.api.nvim_buf_set_name, event.buf, new_bufname)

                if not ok then
                  -- 名前衝突時の処理：既存バッファを削除してリトライ
                  local existing_buf = vim.fn.bufnr(new_bufname)
                  if existing_buf ~= -1 and existing_buf ~= event.buf then
                    vim.api.nvim_buf_delete(existing_buf, { force = true })
                    vim.api.nvim_buf_set_name(event.buf, new_bufname)
                  end
                end

                -- LSPクライアントを再アタッチ（新しいバッファ名で）
                vim.schedule(function()
                  for _, client_id in ipairs(client_ids) do
                    pcall(vim.lsp.buf_attach_client, event.buf, client_id)
                  end
                end)

                vim.b[event.buf].octo_title_processed = true
              end
            end

            vim.schedule(function()
              try_extract_title(1)
            end)
          end
        end,
      })
    end,
  },
}
