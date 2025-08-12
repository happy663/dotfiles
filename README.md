# Dotfiles

主にmacOS環境をメインに設定ファイルを管理している

Nixとhome-managerを使用してパッケージと設定の宣言的管理を行っている

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

ただし初回起動時にnvim-tree-sitterのインストールコマンドが走るのでしばらく操作ができなくなるかもしれない

# Nix

NixとHome Managerを使用して開発環境を宣言的に管理している．

## セットアップ

```bash
# Nixのインストール
sh <(curl -L https://nixos.org/nix/install)

# Home Managerの設定適用
home-manager switch --flake .#$(whoami)
sudo nix run nix-darwin -- switch --flake .#happy-darwin

```

## 主な設定ファイル

- `flake.nix` - Nixの設定のエントリーポイント
- `home.nix` - Home Managerの設定ファイル
- `flake.lock` - 依存関係のロックファイル
