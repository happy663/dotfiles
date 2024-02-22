# Toyama Dotfiles

主にmacOS環境をメインに設定ファイルを管理している

Windows環境でもWSL2でbrewを入れれば構築可能

まだまだファイルの数が少なかったり未完成段階なので,随時更新予定

## コマンド一覧

| コマンド    | 説明                                                                            |
| ----------- | ------------------------------------------------------------------------------- |
| `make init` | XcodeのCommand Line ToolsツールのインストールおよびHomebrewのインストールを行う |
| `make link` | 各種設定ファイルのシンボリックリンクをホームディレクトリに作成する              |
| `make brew` | .Brewfileに従いパッケージをインストールする                                     |

# Neovim

Neovimのプラグインマネージャーにはlazy.nvimを使用している．

https://github.com/folke/lazy.nvim

コマンドラインモードで`:Lazy install`を実行すればプラグインをインストールできる

インストール後は`:Lazy sync`でプラグインを反映できる

# Shell

zshシェルを使用

zshのパスは以下で確認できる

```
brew --prefix zsh
```

zshに変更

```
sudo chsh -s 上記のコマンドのパス
```
