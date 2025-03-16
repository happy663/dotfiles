return {
  {
    -- TODO: filetype declarationが必要なくても選択できるようにしたい
    -- CodeCompanionタブではこれが動かない
    "christoomey/vim-textobj-codeblock",
    lazy = false,
    dependencies = { "kana/vim-textobj-user" },
  },
}
