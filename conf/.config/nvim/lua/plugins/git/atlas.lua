return {
  {
    "emrearmagan/atlas.nvim",
    cond = vim.g.not_in_vscode,
    cmd = "Atlas",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "sindrets/diffview.nvim",
    },
    opts = function()
      -- ghq配下のorgごとに "<org>/*" → "<ghq root>/github.com/<org>/*" を生成する
      -- （repo_configのキーはorg部分にワイルドカードを使えないため）
      local ghq_root = vim.trim(vim.fn.system({ "ghq", "root" }))
      if vim.v.shell_error ~= 0 or ghq_root == "" then
        ghq_root = vim.fn.expand("~/src")
      end
      local paths = {}
      for _, dir in ipairs(vim.fn.glob(ghq_root .. "/github.com/*", false, true)) do
        if vim.fn.isdirectory(dir) == 1 then
          paths[vim.fn.fnamemodify(dir, ":t") .. "/*"] = dir .. "/*"
        end
      end
      return {
        pulls = {
          -- HTTPSだと認証情報がなくキャッシュへのcloneが失敗するためSSHを使う
          git_transport = "ssh",
          -- cwdと別リポジトリのPRでもghqのローカルリポジトリを差分に使う
          repo_config = { paths = paths },
        },
        providers = {
          github = {}, -- gh CLIの認証を利用する
        },
      }
    end,
  },
}
