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
      require("plugins.git.octo.buffer_setup").setup()
      require("plugins.git.octo.buffer_rename").setup()
      require("octo").setup(require("plugins.git.octo.base_config"))
    end,
  },
}
