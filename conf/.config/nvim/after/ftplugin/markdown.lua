-- Markdown用のfoldmethod設定
-- after/ftpluginに配置することで、プラグインのftpluginより後に実行される

-- Treesitter foldingを使用
vim.opt_local.foldmethod = "expr"
-- vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt_local.foldexpr = "v:lua.markdown_fold_all()"
vim.opt_local.foldtext = "v:lua.markdown_foldtext()"
vim.opt_local.foldlevel = 0
vim.opt_local.foldlevelstart = 1
