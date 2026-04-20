# AGENTS.md - dotfiles

このファイルは、このリポジトリで作業するコーディングエージェント向けの指示です。  
Scope: このディレクトリ配下すべて。

## Project Overview
- 個人開発環境を宣言的に管理する dotfiles プロジェクト。
- 対応プラットフォーム:
  - macOS (Apple Silicon)
  - Linux (x86_64)
- 主要スタック:
  - Nix + Home Manager
  - nix-darwin
  - `conf/` 配下で各種ツール設定を一元管理

## Directory Guide
- `conf/`: `$HOME` にシンボリックリンクされる設定本体
- `scripts/`: セットアップ/リンク作成スクリプト
- `flake.nix`, `flake.lock`: Nix 設定と依存ロック
- `Makefile`: 主要操作コマンド
- `README.md`: 全体ドキュメント

## Common Commands
- 初期セットアップ:
  - `make init`
  - `make link`
  - `make brew`
- Nix / Home Manager:
  - `make apply-nix`
  - `make apply-nix-just-home`
  - `make apply-nix-just-darwin`
  - `make update-apply-npm`
- ビルド確認（必要時のみ）:
  - `nix build .#darwinConfigurations.happy-mbp.system`
  - `nix build .#homeConfigurations.happy.activationPackage`

## Editing Policy
- 変更は最小・局所的に行い、既存スタイルを維持すること。
- 主な編集対象は `conf/` と `scripts/`。
- 既存のユーザー設定を勝手に整理・統合・削除しないこと。
- 破壊的コマンドを実行しないこと（明示依頼がある場合を除く）。
  - 例: `rm -rf`, `git reset --hard`, 強制 checkout
- 関係ないローカル変更は revert しないこと。

## Nix Guidance
- パッケージ追加は基本的に `conf/.config/nix/home-manager/common.nix` を優先。
- OS 固有設定は以下に分離:
  - macOS: `conf/.config/nix/home-manager/darwin.nix`
  - Linux: `conf/.config/nix/home-manager/linux.nix`
- nix-darwin 固有は `conf/.config/nix/nix-darwin/default.nix`。

## Neovim Guidance
- `conf/.config/nvim/lua/plugins/` はカテゴリ構造を維持すること。
- 新規プラグインは既存カテゴリへ配置し、`lazy.nvim` 前提で定義すること。
- Lua 変更時は必要に応じて `stylua` で整形すること。

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

## Commit Convention
- Conventional Commits 準拠:
  - `feat:`
  - `fix:`
  - `refactor:`
  - `docs:`
  - `[bot]:`（自動更新系）

## Secrets and Safety
- トークン/鍵/認証情報を出力・コミットしないこと。
- 例: `~/.codex/auth.json` などの機密情報は参照しても内容を露出しないこと。

## Response Style
- 端的かつ実務的に報告すること。
- 最終報告には以下を含めること:
  - 何を変えたか
  - 変更ファイル
  - 実行した検証コマンド
