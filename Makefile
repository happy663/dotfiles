# Do everything.
all: init link brew

# Set initial preference.
init:
	.bin/init.sh

# Link dotfiles.
link:
	.bin/link.sh

# Install macOS applications.
brew:
	.bin/brew.sh
