#!/bin/bash

# yaskkserv2が存在しない場合のみクローンを実行
if [ ! -d "$HOME/src/github.com/wachikun/yaskkserv2" ]; then
  ghq get git@github.com:wachikun/yaskkserv2.git
else
  echo "yaskkserv2 directory already exists. Skipping clone."
fi

cd $HOME/src/github.com/wachikun/yaskkserv2
echo "cd to $(pwd)"

# targetディレクトリが存在しない場合のみビルドを実行
if [ ! -d "target" ]; then
  cargo build --release
else
  echo "yaskkserv2 target directory already exists. Skipping build."
fi

if [ ! -f "/tmp/dictionary.yaskkserv2" ]; then
  yaskkserv2_make_dictionary --dictionary-filename=/tmp/dictionary.yaskkserv2 /Users/happy/src/github.com/happy663/dotfiles/conf/.config/skk/dictionary/SKK-JISYO.L 
  echo "Dictionary created at /tmp/dictionary.yaskkserv2"
else
  echo "/tmp/dictionary.yaskkserv2 already exists. Skipping dictionary creation."
fi

if [ ! -f "/tmp/yaskkserv2.cache" ]; then
  yaskkserv2 --google-cache-filename=/tmp/yaskkserv2.cache /tmp/dictionary.yaskkserv2 
  echo "Google cache created at /tmp/yaskkserv2.cache"
else
  echo "/tmp/yaskkserv2.cache already exists. Skipping google cache creation."
fi

