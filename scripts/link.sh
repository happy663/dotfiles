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

# AI Agent configurations
link_ai_agent_configs() {
    AI_AGENTS_DIR="${DOTFILES_DIR}/.config/ai-agents"

    echo "Setting up AI agent configurations..."

    # Codex (only if ~/.codex exists)
    if [[ -d "$HOME/.codex" ]]; then
        # Link shared skills directory
        ln -snfv "${AI_AGENTS_DIR}/skills" "$HOME/.codex/skills"

        # Link AGENT.md
        ln -snfv "${AI_AGENTS_DIR}/instructions/INSTRUCTIONS.md" "$HOME/.codex/AGENT.md"

        echo "Codex: skills directory and AGENT.md linked"
    fi

    # Claude Code (only if ~/.claude exists)
    if [[ -d "$HOME/.claude" ]]; then
        # Link shared skills directory
        ln -snfv "${AI_AGENTS_DIR}/skills" "$HOME/.claude/skills"

        echo "Claude Code: skills directory linked"
    fi
}

link_ai_agent_configs
