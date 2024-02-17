# Toyama Dotfiles

主にmacOSでの向けでの設定ファイルを管理

Windows環境でもWSL2でbrewを入れれば構築可能

まだまだファイルの数が少なかったり未完成段階なので,随時更新予定

## コマンド一覧

| コマンド | 説明 |
| --- | --- |
| `make init` | XcodeのCommand Line ToolsツールのインストールおよびHomebrewのインストールを行う
| `make link` | 各種設定ファイルのシンボリックリンクをホームディレクトリに作成する |
|`make brew` | .Brewfileに従いパッケージをインストールする |

# Neovim

NeovimのプラグインマネージャーにはPacker.nvimを使用している．

https://github.com/wbthomason/packer.nvim

そのためクローンする必要がある

以下コマンドでクローンできる
```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
 ```

実行後NeovimがPackerコマンドを認識するのでコマンドラインモードで`:PackerInstall`を実行すればプラグインをインストールできる

インストール後は`:PackerSync`でプラグインを反映できる