return {
  {
    "nvim-tree/nvim-tree.lua",
    cond = vim.g.not_in_vscode,
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = {},
        },
        update_focused_file = {
          enable = true,
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          highlight_opened_files = "name",
          icons = {
            glyphs = {
              git = {
                unstaged = "!",
                renamed = "»",
                untracked = "?",
                deleted = "✘",
                staged = "✓",
                unmerged = "",
                ignored = "◌",
              },
            },
          },
        },
        filters = {
          git_ignored = true,
          dotfiles = false,
          custom = {
            "__pycache__",
            -- ".git",
          },
        },
      })
    end,
    dependencies = "nvim-tree/nvim-web-devicons",
  },
}
