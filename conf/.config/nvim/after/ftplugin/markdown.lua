-- Octoと同様に<details>と20行以上のコードブロックを折りたたむ。
-- after/ftpluginで適用し、Octoプラグイン本体のロードには依存しない。
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.require('plugins.git.octo.fold').octo_fold_all()"
vim.opt_local.foldtext = "v:lua.require('plugins.git.octo.fold').octo_foldtext()"
vim.opt_local.foldlevel = 0
vim.opt_local.fillchars:append({ fold = " " })
