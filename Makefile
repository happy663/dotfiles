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
	scripts/update-node-tools.sh --force


