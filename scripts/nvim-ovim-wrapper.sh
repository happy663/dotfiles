#!/bin/sh
# Ovim から起動される nvim に NVIM_APPNAME=ovim-nvim を注入するラッパー
# Ovim の settings.yaml の nvim_path にこのスクリプトのパスを指定する

# GUIアプリからの起動時はシェルのPATHが引き継がれないため補完する
export PATH="$HOME/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# miseでインストールしたneovimへのパスも追加
if [ -d "$HOME/.local/share/mise/shims" ]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

export DOTFILES_DIR="$HOME/src/github.com/happy663/dotfiles"
export NVIM_APPNAME=ovim-nvim
exec nvim "$@"
