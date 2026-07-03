# AGENTS.md - dotfiles

このファイルは、このリポジトリで作業するコーディングエージェント向けの指示です。
Claude Code の `CLAUDE.md` からも `@AGENTS.md` で参照される、プロジェクト共通指示の集約元です。
Scope: このディレクトリ配下すべて。

## Project Overview
- 個人開発環境を宣言的に管理する dotfiles プロジェクト。
- 対応プラットフォーム:
  - macOS (Apple Silicon)
  - Linux (x86_64)
- 主要スタック:
  - Nix + Home Manager（環境の宣言的管理）
  - nix-darwin（macOS 固有設定）
  - 30 以上のツール設定を `conf/` 配下で一元管理
- CI/CD: GitHub Actions で Nix ビルド検証と `flake.lock` の自動更新を行う。

## Directory Structure
```
dotfiles/
├── conf/                       # 設定ファイル（シンボリックリンク対象）
│   ├── .config/               # 標準アプリケーション設定
│   │   ├── nvim/             # Neovim 設定
│   │   ├── nix/              # Nix / Home Manager 設定
│   │   ├── zsh/              # Shell 設定
│   │   ├── git/              # Git 設定
│   │   ├── lazygit/          # Lazygit 設定
│   │   └── ...               # その他 30 以上のツール設定
│   ├── .zshrc                # Zsh 主設定
│   └── .claude/              # Claude Code 設定
├── scripts/                   # セットアップ / リンク作成スクリプト
│   ├── init.sh               # 初期セットアップ
│   ├── link.sh               # シンボリックリンク作成
│   └── after.sh              # インストール後処理
├── .github/workflows/         # GitHub Actions CI/CD
│   ├── build.yaml            # Nix ビルド検証
│   └── update.yaml           # 自動 flake.lock 更新（3日ごと）
├── flake.nix                  # Nix flake 設定
├── flake.lock                 # Nix 依存関係ロック
├── Makefile                   # 主要操作コマンド
└── README.md                  # 全体ドキュメント
```

## Common Commands
- セットアップ（macOS）:
  - `make init`（初期セットアップ）
  - `make link`（dotfiles のシンボリックリンク作成）
  - `make brew`（Homebrew アプリインストール）
- Nix / Home Manager:
  - `make apply-nix`（home-manager + nix-darwin を適用）
  - `make apply-nix-just-home`（Home Manager 設定のみ）
  - `make apply-nix-just-darwin`（nix-darwin 設定のみ）
  - `make update-apply-npm`（node-pkgs を更新して home-manager を適用）
- ビルド確認（CI 相当・必要時のみ）:
  - `nix build .#darwinConfigurations.happy-mbp.system`
  - `nix build .#homeConfigurations.happy.activationPackage`

## Nix Guidance
- パッケージ追加は基本的に `conf/.config/nix/home-manager/common.nix` を優先。
- OS 固有設定は以下に分離:
  - macOS: `conf/.config/nix/home-manager/darwin.nix`
  - Linux: `conf/.config/nix/home-manager/linux.nix`
- nix-darwin 固有は `conf/.config/nix/nix-darwin/default.nix`。

### ファイル構成
- `conf/.config/nix/home-manager/common.nix`: クロスプラットフォーム共通パッケージ
- `conf/.config/nix/home-manager/darwin.nix`: macOS 固有設定
- `conf/.config/nix/home-manager/linux.nix`: Linux 固有設定
- `conf/.config/nix/nix-darwin/default.nix`: nix-darwin 設定

### パッケージ追加手順
1. `conf/.config/nix/home-manager/common.nix` の `home.packages` に追加
2. `home-manager switch --flake .` で適用
3. コミット（`feat: Add <package-name> to Nix packages`）

## Neovim Guidance
- `conf/.config/nvim/lua/plugins/` はカテゴリ構造を維持すること。
- 新規プラグインは既存カテゴリへ配置し、`lazy.nvim` 前提で定義すること。
- Lua 変更時は必要に応じて `stylua` で整形すること。

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
    └── plugins/               # プラグイン設定（17 カテゴリ）
        ├── ai/                # AI 統合（CodeCompanion, Copilot 等）
        ├── completion/        # 補完（nvim-cmp, LuaSnip 等）
        ├── lsp/               # LSP（mason, lspconfig, none-ls 等）
        ├── edit_support/      # 編集補助（autopairs, surround 等）
        ├── fuzzyfinder/       # ファジー検索（Telescope）
        ├── git/               # Git 統合（diffview, octo 等）
        ├── japanese/          # 日本語対応（kensaku, skkleton 等）
        ├── navigation/        # ナビゲーション（flash, hop 等）
        ├── languages/         # 言語別プラグイン（vimtex, metals 等）
        ├── note/              # ノート機能（orgmode, markdown 等）
        ├── terminal/          # ターミナル（toggleterm 等）
        ├── tools/             # ツール統合（which-key, overseer 等）
        ├── highlight/         # ハイライト（hlchunk 等）
        ├── treesitter/        # 構文解析（treesitter 等）
        ├── ui/                # UI 改善（nvim-tree, lualine 等）
        ├── colorschemas/      # カラースキーム
        └── misc/              # その他
```

### コードフォーマット（StyLua）
- pre-commit フックが設定されており、Lua ファイル編集時に自動整形される。
- 設定: `.pre-commit-config.yaml`（StyLua v0.20.0）。
- コミット前に自動実行される。

## Agent CLI Usage
- Claude Code / Codex は Neovim のターミナルバッファ内で使用している。
- `conf/.config/nvim/lua/agent_term/` にターミナル管理モジュールがある。
- 主要コマンド: AgentClaude, AgentCodex, AgentClaudeRestart, AgentClaudeFork など。
- エージェント CLI に関する提案は、tmux 直接ではなく Neovim コマンド経由を優先すること。

## Development Workflow

### コミット規約
- Conventional Commits 準拠:
  - `feat:`（新機能追加）
  - `fix:`（バグ修正）
  - `refactor:`（リファクタリング）
  - `docs:`（ドキュメント更新）
  - `[bot]:`（自動更新系・flake.lock 等）
- 言語: 英語または日本語（混在可）。

### ブランチ命名規則
- `feat-*` / `feat/*`: 新機能
- `fix-*` / `fix/*`: バグ修正
- `refactor-*` / `refactor/*`: リファクタリング
- `update/*`: 更新
- `auto-updates`: 自動更新用（GitHub Actions）

## Editing Policy
- 変更は最小・局所的に行い、既存スタイルを維持すること。
- 主な編集対象は `conf/` と `scripts/`。
- 既存のユーザー設定を勝手に整理・統合・削除しないこと。
- 破壊的コマンドを実行しないこと（明示依頼がある場合を除く）。
  - 例: `rm -rf`, `git reset --hard`, 強制 checkout
- 関係ないローカル変更は revert しないこと。

## Validation Policy
- まず変更箇所に近い軽量検証を優先すること。
- 大規模・長時間の検証は、必要性がある場合のみ実行すること。
- 無関係な不具合修正は行わないこと。

## Command Safety
- `rg` / `find` / `du` などの再帰検索は、対象ディレクトリを必要最小限に絞ること。
- `~/.npm`, `~/.local/share`, `~/.cache`, `node_modules`, `.git`, `mise` などの巨大なキャッシュ・依存ディレクトリ全体を安易に検索しないこと。
- ホーム配下や共有データ配下を調査する場合は、まず具体的なファイル・プラグイン・ログディレクトリに限定すること。
- 広めの検索が必要な場合は、`--glob` による除外、`--max-filesize`、`-m` / `--max-count` などで走査量と出力量を制限すること。
- `2>/dev/null` で stderr を捨てても stdout の大量出力は残るため、CodeCompanion / Codex 上で固まる原因になる。大量出力が予想される場合は、検索対象や件数を先に絞ること。

## Secrets and Safety
- トークン/鍵/認証情報を出力・コミットしないこと。
- 例: `~/.codex/auth.json` などの機密情報は参照しても内容を露出しないこと。

## Response Style
- 端的かつ実務的に報告すること。
- 最終報告には以下を含めること:
  - 何を変えたか
  - 変更ファイル
  - 実行した検証コマンド
