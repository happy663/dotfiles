#!/bin/zsh

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi


# Install xcode
xcode-select --install > /dev/null

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


# Install Nix
sh <(curl -L https://nixos.org/nix/install)



