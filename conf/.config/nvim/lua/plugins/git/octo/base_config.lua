-- Configuration object for octo.setup()

return {
  mappings_disable_default = true, -- disable default mappings if true, but will still adapt user mappings
  use_local_fs = false, -- use local files on right side of reviews
  enable_builtin = false, -- shows a list of builtin actions when no action is provided
  default_remote = { "upstream", "origin" }, -- order to try remotes
  default_merge_method = "merge", -- default merge method which should be used for both `Octo pr merge` and merging from picker, could be `commit`, `rebase` or `squash`
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
    nacks = { -- snacks specific config
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
  resolved_icon = " ", -- resolved indicator
  reaction_viewer_hint_icon = " ", -- marker for user reactions
  commands = {}, -- additional subcommands made available to `Octo` command
  users = "search", -- Users for assignees or reviewers. Values: "search" | "mentionable" | "assignable"
  user_icon = " ", -- user icon
  ghost_icon = "󰊠 ", -- ghost icon
  timeline_marker = " ", -- timeline marker
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
  default_to_projects_v2 = true, -- use projects v2 for the `Octo card ...` command by default. Both legacy and v2 commands are available under `Octo cardlegacy ...` and `Octo cardv2 ...` respectively.
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
  mappings = {
    runs = {
      open_in_browser = { lhs = "<leader>ob", desc = "open workflow run in browser" },
      rerun = { lhs = "<C-o>", desc = "rerun workflow" },
      rerun_failed = { lhs = "<C-f>", desc = "rerun failed workflow" },
      cancel = { lhs = "<C-x>", desc = "cancel workflow" },
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      expand_step = { lhs = "o", desc = "expand workflow step" },
    },
    issue = {
      goto_issue = { lhs = "<C-]>", desc = "navigate to a local repo issue" },
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      close_issue = { lhs = "<leader>oic", desc = "close issue" },
      open_in_browser = { lhs = "<leader>ob", desc = "open issue in browser" },
      reopen_issue = { lhs = "", desc = "reopen issue" },
      list_issues = { lhs = "", desc = "list open issues on same repo" },
      reload = { lhs = "", desc = "reload issue" }, -- カスタム実装を使用するため無効化
      add_assignee = { lhs = "", desc = "add assignee" },
      remove_assignee = { lhs = "", desc = "remove assignee" },
      create_label = { lhs = "", desc = "create label" },
      add_label = { lhs = "", desc = "add label" },
      remove_label = { lhs = "", desc = "remove label" },
      -- goto_issue = { lhs = "", desc = "navigate to a local repo issue" },
      issue_options = { lhs = "", desc = "show issue options" },
      -- add_comment = { lhs = "<leader>oa", desc = "add comment" },
      delete_comment = { lhs = "", desc = "delete comment" },
      react_hooray = { lhs = "", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "", desc = "add/remove 😕 reaction" },
    },
    pull_request = {
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      pr_options = { lhs = "", desc = "show PR options" },
      checkout_pr = { lhs = "", desc = "checkout PR" },
      merge_pr = { lhs = "", desc = "merge commit PR" },
      squash_and_merge_pr = { lhs = "sm", desc = "squash and merge PR" },
      rebase_and_merge_pr = { lhs = "rm", desc = "rebase and merge PR" },
      list_commits = { lhs = "", desc = "list PR commits" },
      list_changed_files = { lhs = "", desc = "list PR changed files" },
      show_pr_diff = { lhs = "", desc = "show PR diff" },
      add_reviewer = { lhs = "", desc = "add reviewer" },
      remove_reviewer = { lhs = "", desc = "remove reviewer request" },
      close_issue = { lhs = "", desc = "close PR" },
      reopen_issue = { lhs = "", desc = "reopen PR" },
      list_issues = { lhs = "", desc = "list open issues on same repo" },
      reload = { lhs = "", desc = "reload PR" }, -- カスタム実装を使用するため無効化
      open_in_browser = { lhs = "<leader>ob", desc = "open PR in browser" },
      copy_sha = { lhs = "", desc = "copy commit SHA to system clipboard" },
      -- goto_file = { lhs = "gf", desc = "go to file" },
      add_assignee = { lhs = "", desc = "add assignee" },
      remove_assignee = { lhs = "", desc = "remove assignee" },
      create_label = { lhs = "", desc = "create label" },
      add_label = { lhs = "", desc = "add label" },
      remove_label = { lhs = "", desc = "remove label" },
      -- goto_issue = { lhs = "<leader>go", desc = "navigate to a local repo issue" },
      goto_issue = { lhs = "<C-]>", desc = "navigate to a local repo issue" },
      -- add_comment = { lhs = "<leader>oa", desc = "add comment" },
      delete_comment = { lhs = "", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      react_hooray = { lhs = "", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "", desc = "add/remove 😕 reaction" },
      review_start = { lhs = "", desc = "start a review for the current PR" },
      review_resume = { lhs = "", desc = "resume a pending review for the current PR" },
      resolve_thread = { lhs = "", desc = "resolve PR thread" },
      unresolve_thread = { lhs = "", desc = "unresolve PR thread" },
    },
    review_thread = {
      -- goto_issue = { lhs = "", desc = "navigate to a local repo issue" },
      goto_issue = { lhs = "<C-]>", desc = "navigate to a local repo issue" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      select_next_entry = { lhs = "]q", desc = "move to next changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
      select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
      select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      add_comment = { lhs = "", desc = "add comment" },
      add_suggestion = { lhs = "", desc = "add suggestion" },
      delete_comment = { lhs = "", desc = "delete comment" },
      react_hooray = { lhs = "", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "", desc = "add/remove 😕 reaction" },
      resolve_thread = { lhs = "", desc = "resolve PR thread" },
      unresolve_thread = { lhs = "", desc = "unresolve PR thread" },
    },
    submit_win = {
      approve_review = { lhs = "<C-a>", desc = "approve review", mode = { "n", "i" } },
      comment_review = { lhs = "<C-m>", desc = "comment review", mode = { "n", "i" } },
      request_changes = { lhs = "<C-r>", desc = "request changes review", mode = { "n", "i" } },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab", mode = { "n", "i" } },
    },
    review_diff = {
      submit_review = { lhs = "", desc = "submit review" },
      discard_review = { lhs = "", desc = "discard review" },
      copy_sha = { lhs = "", desc = "copy commit SHA to system clipboard" },
      add_review_comment = { lhs = "", desc = "add a new review comment", mode = { "n", "x" } },
      add_review_suggestion = {
        lhs = "",
        desc = "add a new review suggestion",
        mode = { "n", "x" },
      },
      focus_files = { lhs = "", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "", desc = "hide/show changed files panel" },
      next_thread = { lhs = "]t", desc = "move to next thread" },
      prev_thread = { lhs = "[t", desc = "move to previous thread" },
      select_next_entry = { lhs = "]q", desc = "move to next changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
      select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
      select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "space>", desc = "toggle viewer viewed state" },
      -- goto_file = { lhs = "gf", desc = "go to file" },
    },
    file_panel = {
      submit_review = { lhs = "", desc = "submit review" },
      discard_review = { lhs = "", desc = "discard review" },
      next_entry = { lhs = "j", desc = "move to next changed file" },
      prev_entry = { lhs = "k", desc = "move to previous changed file" },
      select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
      refresh_files = { lhs = "R", desc = "refresh changed files panel" },
      focus_files = { lhs = "", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "", desc = "hide/show changed files panel" },
      select_next_entry = { lhs = "]q", desc = "move to next changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
      select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
      select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "space>", desc = "toggle viewer viewed state" },
    },
    notification = {
      read = { lhs = "", desc = "mark notification as read" },
      done = { lhs = "", desc = "mark notification as done" },
      unsubscribe = { lhs = "", desc = "unsubscribe from notifications" },
    },
  },
}

