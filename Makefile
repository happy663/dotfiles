# Do everything.
all: init link brew update-apply-npm

# Set initial preference.
init:
	scripts/init.sh

# Link dotfiles.
link:
	scripts/link.sh

# Install macOS applications.
brew:
	scripts/brew.sh

apply-nix:
	nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig-darwin
	sudo nix run nix-darwin -- switch --flake .#happy-darwin

apply-nix-just-home:
	nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig-darwin

apply-nix-just-darwin:
	sudo nix run nix-darwin -- switch --flake .#happy-darwin
		
update-apply-npm:
	cd conf/.config/nix/node-pkgs && rm package-lock.json
	cd conf/.config/nix/node-pkgs && npm install --package-lock-only
	nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig-darwin

# nippo (Claude Code / Codex 日報スキル) を導入
# Rust バイナリのインストールと skill symlink の作成
setup-nippo:
	scripts/install-nippo.sh
	scripts/link.sh

# ~/.claude/settings.json から base.json と ~/.claude/settings.local.json を再構築
claude-pull:
	scripts/claude-settings.sh pull

# base.json と ~/.claude/settings.local.json をマージして ~/.claude/settings.json を生成
claude-push:
	scripts/claude-settings.sh push

# GLM5.2 (z.ai) 接続モードに切替
claude-glm:
	scripts/claude-mode.sh glm

# 素の Claude + Fable モードに切替
claude-fable:
	scripts/claude-mode.sh fable

# 素の Claude + Opus 4.7 (1M) モードに切替
claude-opus47:
	scripts/claude-mode.sh opus47

# Ovim 専用 Neovim 設定 (NVIM_APPNAME=ovim-nvim) のセットアップ
# 1. 専用設定で lazy.nvim を起動しプラグインを取得
# 2. ラッパースクリプトを ~/.local/bin に配置して実行可能にする
# 3. Ovim の settings.yaml の nvim_path をラッパーのパスに更新する
setup-ovim:
	NVIM_APPNAME=ovim-nvim nvim --headless "+Lazy! sync" +qa
	mkdir -p ~/.local/bin
	cp scripts/nvim-ovim-wrapper.sh ~/.local/bin/nvim-ovim
	chmod +x ~/.local/bin/nvim-ovim
	@echo "Done. Set nvim_path to $$HOME/.local/bin/nvim-ovim in Ovim settings."


