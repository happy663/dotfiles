# CLAUDE.md - dotfiles

## Project Overview

このリポジトリは個人開発環境を宣言的に管理するdotfilesプロジェクトです。

**対応プラットフォーム**:

- macOS (Apple Silicon)
- Linux (x86_64)

**主要技術スタック**:

- Nix + Home Manager - 環境の宣言的管理
- nix-darwin - macOS固有設定
- 30以上のツール設定を統合管理

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

# 依存関係を更新してhome-manager+nix-darwinを適用
nix run .#update

# Home Manager設定を適用
nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig-darwin

# macOS設定を適用（nix-darwin）
sudo nix run nix-darwin -- switch --flake .#happy-darwin

# 依存関係を更新
nix flake update

# ビルド確認（CI相当）
nix build .#darwinConfigurations.happy-mbp.system
nix build .#homeConfigurations.happy.activationPackage
```

## Nix Configuration

### ファイル構成

- **`conf/.config/nix/home-manager/common.nix`** - クロスプラットフォーム共通パッケージ
- **`conf/.config/nix/home-manager/darwin.nix`** - macOS固有設定
- **`conf/.config/nix/home-manager/linux.nix`** - Linux固有設定
- **`conf/.config/nix/nix-darwin/default.nix`** - nix-darwin設定

### パッケージ追加手順

1. `conf/.config/nix/home-manager/common.nix`の`home.packages`に追加
2. `home-manager switch --flake .`で適用
3. コミット（`feat: Add <package-name> to Nix packages`）

### 管理されている主要ツール

- **CLI**: bat, fd, ripgrep, fzf, gh, ghq, mise, zoxide, delta
- **開発**: cargo, docker, docker-compose, colima, deno, nodejs
- **言語**: PHP 7.4/8.4, Go, Python, Rust, Haskell
- **エディタ**: neovim, neovim-remote
- **その他**: lazygit, firefox, neofetch

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

### プラグイン管理（lazy.nvim）

**lazy.nvim**を使用してプラグインを遅延読み込み・管理しています。

**新規プラグイン追加手順**:

1. 適切なカテゴリディレクトリを選択（例: `lua/plugins/tools/`）
2. 新しいLuaファイルを作成（例: `my-plugin.lua`）
3. プラグイン定義を記述:
   ```lua
   return {
     "author/plugin-name",
     event = "VeryLazy",  -- 遅延読み込みトリガー
     config = function()
       -- プラグイン設定
     end,
   }
   ```
4. Neovimを再起動すると自動でインストールされる
5. `:Lazy`でプラグインマネージャーUI確認

**よく使うevent**:

- `VeryLazy` - 起動後の遅延読み込み
- `BufRead` - バッファ読み込み時
- `InsertEnter` - インサートモード時
- `LspAttach` - LSP接続時

### コードフォーマット（StyLua）

**pre-commitフック**が設定されており、Luaファイル編集時に自動整形されます。

- 設定: `.pre-commit-config.yaml`
- StyLua v0.20.0を使用
- コミット前に自動実行

### 主要プラグイン

- **CodeCompanion** - Claude統合（ローカルビルド版使用）
- **GitHub Copilot** - AI補完
- **nvim-cmp** - 補完エンジン
- **mason.nvim** - LSPサーバー管理
- **Telescope** - ファジーファインダー
- **nvim-tree** - ファイラー
- **orgmode** - Org-mode対応

## Shell Configuration

### Zsh構成

```
conf/.config/zsh/
├── init.zsh             # 初期化
├── environment.zsh      # 環境変数
├── plugins.zsh          # プラグイン管理（Zinit）
├── completion.zsh       # 補完設定
├── functions.zsh        # カスタム関数
├── aliases.zsh          # エイリアス
├── keybindings.zsh      # キーバインディング
├── navigation.zsh       # ナビゲーション
└── history.zsh          # 履歴管理
```

**プラグインマネージャー**: Zinit

**主要プラグイン**:

- Powerlevel10k - プロンプトテーマ
- zsh-autosuggestions - コマンド補完提案
- fast-syntax-highlighting - シンタックスハイライト
- zeno.zsh - シェルコマンド補完UI

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

- `feat-*` または `feat/*` - 新機能
- `fix-*` または `fix/*` - バグ修正
- `refactor-*` または `refactor/*` - リファクタリング
- `update/*` - 更新
- `auto-updates` - 自動更新用（GitHub Actions）

### 自動化ワークフロー

**GitHub Actions**:

1. **build.yaml** - Nix設定ビルド検証

   - トリガー: `.nix`または`flake.lock`変更時、PR
   - macOS 15で実行
   - Cachix統合

2. **update.yaml** - 自動依存更新
   - スケジュール: 3日ごと（UTC 15:00 = JST 00:00）
   - `nix flake update`実行
   - `auto-updates`ブランチにPR自動作成
