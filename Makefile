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

# Hammerspoon等の自動実行から呼ぶ用。home-manager評価ファイルが
# clean な場合のみ update-apply-npm を実行する。
auto-update-node-pkgs:
	scripts/auto-update-node-pkgs.sh



