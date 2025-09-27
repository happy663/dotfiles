# Dotfiles

macOS環境をメインに設定ファイルを管理している
Nixとhome-managerを使用してパッケージと設定の宣言的管理を行っている

## コマンド一覧

| コマンド    | 説明                                                               |
| ----------- | ------------------------------------------------------------------ |
| `make init` | XcodeのCommand Line Toolsツールのインストールなどを行う            |
| `make link` | 各種設定ファイルのシンボリックリンクをホームディレクトリに作成する |

## Nix

NixとHome Managerを使用して開発環境を宣言的に管理している．

### セットアップ

```bash
# Nixのインストール
sh <(curl -L https://nixos.org/nix/install)

# nixpkgのinstallとupdate
nix run .#update

```

### 主な設定ファイル

- `flake.nix` - Nixの設定のエントリーポイント
- `home.nix` - Home Managerの設定ファイル
- `flake.lock` - 依存関係のロックファイル

## Neovim

Neovimのプラグインマネージャーにはlazy.nvimを使用している．
コマンドラインモードで`:Lazy install`を実行すればプラグインをインストールできる
インストール後は`:Lazy sync`でプラグインを反映できる
