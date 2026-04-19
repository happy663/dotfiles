# CLAUDE.md - dotfiles

## Project Overview

このリポジトリは個人開発環境を宣言的に管理するdotfilesプロジェクトです。

**対応プラットフォーム**:

* macOS (Apple Silicon)
* Linux (x86_64)

**主要技術スタック**:

* Nix + Home Manager - 環境の宣言的管理
* nix-darwin - macOS固有設定
* 30以上のツール設定を統合管理

## Directory Structure

```
dotfiles/
├── conf/                       # 設定ファイル（シンボリンク対象）
│   ├── .config/               # 標準アプリケーション設定
│   │   ├── nvim/             # Neovim設定
│   │   ├── nix/              # Nix/Home Manager設定
│   │   ├── zsh/              # Shell設定
│   │   ├── git/              # Git設定
│   │   ├── lazygit/          # Lazygit設定
│   │   └── ...               # その他30以上のツール設定
│   ├── .zshrc                # Zsh主設定
│   └── .claude/              # Claude Code設定
├── scripts/                   # セットアップスクリプト
│   ├── init.sh               # 初期セットアップ
│   ├── link.sh               # シンボリンク作成
│   └── after.sh              # インストール後処理
├── .github/workflows/         # GitHub Actions CI/CD
│   ├── build.yaml            # Nixビルド検証
│   └── update.yaml           # 自動flake.lock更新（3日ごと）
├── flake.nix                  # Nix flake設定
├── flake.lock                 # Nix依存関係ロック
├── Makefile                   # コマンドショートカット
└── README.md                  # ドキュメント
```

## Common Commands

### セットアップ

```bash
# 初期セットアップ（macOS）
make init

# dotfilesのシンボリンク作成
make link

# Homebrewアプリインストール
make brew
```

### Nix/Home Manager操作

```bash
# home-manager + nix-darwinを適用
make apply-nix

# Home Manager設定のみを適用
make apply-nix-just-home

# nix-darwin設定のみを適用
make apply-nix-just-darwin

# node-pkgsを更新してhome-managerを適用
make update-apply-npm

# ビルド確認（CI相当）
nix build .#darwinConfigurations.happy-mbp.system
nix build .#homeConfigurations.happy.activationPackage
```

## Nix Configuration

### ファイル構成

* **`conf/.config/nix/home-manager/common.nix`** - クロスプラットフォーム共通パッケージ
* **`conf/.config/nix/home-manager/darwin.nix`** - macOS固有設定
* **`conf/.config/nix/home-manager/linux.nix`** - Linux固有設定
* **`conf/.config/nix/nix-darwin/default.nix`** - nix-darwin設定

### パッケージ追加手順

1. `conf/.config/nix/home-manager/common.nix`の`home.packages`に追加
2. `home-manager switch --flake .`で適用
3. コミット（`feat: Add <package-name> to Nix packages`）

## Neovim Configuration

### ディレクトリ構造

```
conf/.config/nvim/
├── init.lua                   # エントリーポイント
├── lazy-lock.json             # プラグインバージョンロック
└── lua/
    ├── core/                  # コア設定
    │   ├── settings.lua       # 基本設定
    │   ├── keymaps.lua        # キーマップ
    │   └── auto-command.lua   # 自動コマンド
    └── plugins/               # プラグイン設定（17カテゴリ）
        ├── ai/                # AI統合（CodeCompanion, Copilot等）
        ├── completion/        # 補完（nvim-cmp, LuaSnip等）
        ├── lsp/               # LSP（mason, lspconfig, none-ls等）
        ├── edit_support/      # 編集補助（autopairs, surround等）
        ├── fuzzyfinder/       # ファジー検索（Telescope）
        ├── git/               # Git統合（diffview, octo等）
        ├── japanese/          # 日本語対応（kensaku, skkleton等）
        ├── navigation/        # ナビゲーション（flash, hop等）
        ├── languages/         # 言語別プラグイン（vimtex, metals等）
        ├── note/              # ノート機能（orgmode, markdown等）
        ├── terminal/          # ターミナル（toggleterm等）
        ├── tools/             # ツール統合（which-key, overseer等）
        ├── highlight/         # ハイライト（hlchunk等）
        ├── treesitter/        # 構文解析（treesitter等）
        ├── ui/                # UI改善（nvim-tree, lualine等）
        ├── colorschemas/      # カラースキーム
        └── misc/              # その他
```

### コードフォーマット（StyLua）

**pre-commitフック**が設定されており、Luaファイル編集時に自動整形されます。

* 設定: `.pre-commit-config.yaml`
* StyLua v0.20.0を使用
* コミット前に自動実行

## Development Workflow

### コミット規約

**Conventional Commits**準拠:

```
feat: 新機能追加
fix: バグ修正
refactor: リファクタリング
docs: ドキュメント更新
[bot]: 自動更新（flake.lock等）
```

**言語**: 英語または日本語（混在可）

### ブランチ戦略

**命名規則**:

* `feat-*` または `feat/*` - 新機能
* `fix-*` または `fix/*` - バグ修正
* `refactor-*` または `refactor/*` - リファクタリング
* `update/*` - 更新
* `auto-updates` - 自動更新用（GitHub Actions）
