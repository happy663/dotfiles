return {
  {
    "nvim-tree/nvim-tree.lua",
    cond = vim.g.not_in_vscode,
    lazy = true,
    keys = {
      {
        "<C-b>",
        "<cmd>NvimTreeToggle<CR>",
        desc = "NvimTreeToggle",
      },
    },
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile" },
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
            "^.git$",
          },
        },
      })
      local map = vim.api.nvim_set_keymap

      local api = require("nvim-tree.api")
      vim.keymap.set("n", "<leader>ea", function()
        api.tree.expand_all()
      end, { silent = true, nowait = true, desc = "Expand all" })

      vim.keymap.set("n", "<leader>ec", function()
        api.tree.collapse_all()
      end, { silent = true, nowait = true, desc = "Collapse all" })

      vim.keymap.set("n", "<leader>ei", function()
        api.tree.toggle_gitignore_filter()
      end, { silent = true, nowait = true, desc = "Toggle gitignore filter" })

      -- キーマップはkeysで定義済み

      vim.api.nvim_set_var("loaded_netrw", 1)
      vim.api.nvim_set_var("loaded_netrwPlugin", 1)
    end,

    dependencies = "nvim-tree/nvim-web-devicons",
  },
}
