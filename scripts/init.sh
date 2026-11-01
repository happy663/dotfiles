#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi


# Install xcode (すでに導入済みの場合 xcode-select は非 0 を返すため無視する)
xcode-select --install > /dev/null || true

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"



