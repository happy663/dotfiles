return {
  {
    "kdheepak/lazygit.nvim",
    cond = vim.g.not_in_vscode,
    lazy = false,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension("lazygit")

      local smear_cursor = require("smear_cursor")
      local function setup_lazygit_keymaps()
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(0, "t", "<C-n>", "<Down>", opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-p>", "<Up>", opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<esc>", opts)
      end

      local function get_lazygit_smear_config(is_active)
        return {
          smear_between_buffers = is_active,
          smear_between_neighbor_lines = is_active,
          scroll_buffer_space = false,
          legacy_computing_symbols_support = is_active,
          smear_insert_mode = is_active,
          stiffness = is_active and 0.6 or 0,
          trailing_stiffness = is_active and 0.3 or 0,
          trailing_exponent = is_active and 2 or 0,
          slowdown_exponent = 0,
          distance_stop_animating = is_active and 0.1 or 0,
        }
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*lazygit*",
        callback = function()
          setup_lazygit_keymaps()
        end,
      })

      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "term://*lazygit*",
        callback = function()
          smear_cursor.setup(get_lazygit_smear_config(true))
        end,
      })
    end,
  },
}
