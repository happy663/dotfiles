#!/bin/zsh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ $# -gt 0 ]]; then
    if [[ -z "$1" ]]; then
        echo "Error: empty worktree path. Cancelled."
        exit 1
    fi
    DOTFILES_DIR="$1/conf"
else
    DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/conf"
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Error: $DOTFILES_DIR does not exist."
    exit 1
fi

echo "Creating symlinks from ${DOTFILES_DIR} to $HOME"

# ========================================
# トップレベルのドットファイル（.zshrc, .p10k.zsh等）
# .config, .claude, .codex は個別リンクで処理するためスキップ
# ========================================
for dotfile in "${DOTFILES_DIR}"/.??* ; do
    filename=$(basename "$dotfile")

    [[ "$filename" == ".git" ]] && continue
    [[ "$filename" == ".github" ]] && continue
    [[ "$filename" == ".DS_Store" ]] && continue
    [[ "$filename" == ".config" ]] && continue
    [[ "$filename" == ".claude" ]] && continue
    [[ "$filename" == ".codex" ]] && continue

    ln -snfv "$dotfile" "$HOME/$filename"
done

echo ""
echo "=== ~/.config ==="
mkdir -p "$HOME/.config"

for dir in "${DOTFILES_DIR}"/.config/*/; do
    [[ ! -d "$dir" ]] && continue
    dirname=$(basename "$dir")

    # リンクしないディレクトリ（git管理対象なし）
    case "$dirname" in
        colima|gh|fish|github-copilot) continue ;;
    esac

    ln -snfv "$dir" "$HOME/.config/$dirname"
done

echo ""
echo "=== ~/.claude ==="
mkdir -p "$HOME/.claude"

# ディレクトリ
for target in commands commands.old output-styles skills scripts; do
    if [[ -e "${DOTFILES_DIR}/.claude/${target}" ]]; then
        ln -snfv "${DOTFILES_DIR}/.claude/${target}" "$HOME/.claude/${target}"
    fi
done

# ファイル
for target in CLAUDE.md statusline-script.sh; do
    if [[ -e "${DOTFILES_DIR}/.claude/${target}" ]]; then
        ln -snfv "${DOTFILES_DIR}/.claude/${target}" "$HOME/.claude/${target}"
    fi
done

# settings.json は base.json + ~/.claude/settings.local.json をマージして実ファイル生成
"${SCRIPT_DIR}/claude-settings.sh" push

echo ""
echo "=== ~/.codex ==="
mkdir -p "$HOME/.codex"

for target in codex-notify rules skills; do
    if [[ -e "${DOTFILES_DIR}/.codex/${target}" ]]; then
        ln -snfv "${DOTFILES_DIR}/.codex/${target}" "$HOME/.codex/${target}"
    fi
done

for target in AGENT.md config.toml; do
    if [[ -e "${DOTFILES_DIR}/.codex/${target}" ]]; then
        ln -snfv "${DOTFILES_DIR}/.codex/${target}" "$HOME/.codex/${target}"
    fi
done

