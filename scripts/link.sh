#!/bin/zsh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/conf"

echo "Creating symlinks from ${DOTFILES_DIR} to $HOME"

for dotfile in "${DOTFILES_DIR}"/.??* ; do
    # Skip certain files/directories
    [[ $(basename "$dotfile") == ".git" ]] && continue
    [[ $(basename "$dotfile") == ".github" ]] && continue
    [[ $(basename "$dotfile") == ".DS_Store" ]] && continue

    # Get just the filename
    filename=$(basename "$dotfile")
    # Create symlink to home directory
    ln -snfv "$dotfile" "$HOME/$filename"
done