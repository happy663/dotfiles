-- Octo.nvim: GitHub integration for Neovim
-- Modular structure with separated concerns
local helpers = require("plugins.git.octo.helpers")

return {
  {
    "pwntester/octo.nvim",
    lazy = true,
    cmd = { "Octo" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
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
        "<leader>olch",
        "<cmd>Octo issue list assignee=happy663 states=CLOSED<CR>",
        desc = "Open Octo issues assigned to happy663",
      },
      {
        "<leader>olca",
        "<cmd>Octo issue list states=CLOSED<CR>",
        desc = "Open Octo closed issues",
      },
      { "<leader>oll", "<cmd>Octo issue list<CR>", desc = "Open Octo issues" },
      { "<leader>oin", "<cmd>Octo issue create<CR>", desc = "Create a new Octo issue" },
      { "<leader>oc", "<cmd>Octo actions<CR>", desc = "Open Octo actions" },
      {
        "<leader>opa",
        "<cmd>Octo search author:@me is:open is:pr<CR>",
        desc = "My created PRs (all repos)",
      },
      {
        "<leader>opr",
        "<cmd>Octo search review-requested:@me is:open is:pr<CR>",
        desc = "PRs requesting my review (all repos)",
      },
      {
        "<leader>opl",
        "<cmd>Octo pr list<CR>",
        desc = "Open Octo pull requests",
      },
      {
        "<leader>ois",
        function()
          helpers.search_issues("all")
        end,
        desc = "Octo: Search (title + body)",
      },
    },
    config = function()
      require("octo.pickers.telescope.provider")
      require("plugins.git.octo.buffer_rename").setup()
      require("octo").setup(require("plugins.git.octo.base_config"))

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function()
          -- Basic buffer settings
          vim.cmd([[setlocal wrap]])
          vim.cmd([[setlocal linebreak]])
          -- Register treesitter for render-markdown
          -- Use markdown parser in octo buffers
          vim.treesitter.language.register("markdown", "octo")
          -- URL highlighting
          vim.fn.matchadd("Underlined", "https\\?://[^ )>]*")
          -- Or custom highlight group
          vim.cmd([[ highlight MarkdownURL guifg=#569CD6 gui=underline ctermfg=75 cterm=underline ]])
          vim.fn.matchadd("MarkdownURL", "https\\?://[^ )>]*")
          -- Prevent nvim-markdown's loadview from overwriting highlight settings
          vim.api.nvim_set_hl(0, "Folded", {
            fg = "#82aaff", -- Bright blue (harmonizes with tokyonight-moon)
            bg = "#1e2030", -- Slightly darker background
            italic = true,
          })
          vim.api.nvim_set_hl(0, "FoldColumn", {
            fg = "#636da6",
            bg = "NONE",
          })
          -- プラグイン側に上書きされないように、遅延して実行
          -- https://github.com/pwntester/octo.nvim/blob/4a3a4fc5a9d3a372c91041f5b846f33b8d6b31fa/lua/octo/model/octo-buffer.lua#L213
          vim.schedule(function()
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr = "v:lua.require('plugins.git.octo.fold').octo_fold_all()"
            vim.opt_local.foldtext = "v:lua.require('plugins.git.octo.fold').octo_foldtext()"
            vim.opt_local.foldlevel = 0
            vim.opt_local.conceallevel = 0
            -- Ensure fold display is visible
            vim.opt_local.fillchars:append({ fold = " " })
          end)

          require("plugins.git.octo.buffer_keymaps").octo_buffer_keymaps()
          require("utils.markdown-helpers").setup_keymaps()
        end,
      })
    end,
  },
}
