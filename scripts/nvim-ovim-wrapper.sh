#!/bin/sh
# Ovim から起動される nvim に NVIM_APPNAME=ovim-nvim を注入するラッパー
# Ovim の settings.yaml の nvim_path にこのスクリプトのパスを指定する
export NVIM_APPNAME=ovim-nvim
exec nvim "$@"
