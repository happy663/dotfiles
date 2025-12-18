# Dotfiles

Personal dotfiles repository. Development environment is declaratively managed using Nix and Home Manager.

## Supported Platforms

- macOS (Apple Silicon)
- Linux (x86_64)

## Setup

```bash
# 1. Initial setup (macOS only - Xcode Command Line Tools, etc.)
make init

# 2. Install Nix
sh <(curl -L https://nixos.org/nix/install)

# 3. Build Nix environment (flake update + Home Manager + nix-darwin)
nix run .#update

# 4. Create symlinks for dotfiles
make link

# 5. Install Neovim plugins
nvim -c "Lazy install"
```

## Repository Structure

```
dotfiles/
├── conf/              # Configuration files
│   ├── .config/       # Application configurations
│   │   ├── nvim/      # Neovim configuration
│   │   ├── wezterm/   # Wezterm configuration
│   │   ├── zsh/       # Zsh configuration
│   │   ├── git/       # Git configuration
│   │   └── ...        # 30+ other tool configurations
│   ├── .zshrc         # Main Zsh configuration
│   └── .claude/       # Claude Code configuration
├── scripts/           # Setup scripts
│   ├── init.sh        # Initialization script
│   └── link.sh        # Symlink creation
├── flake.nix          # Nix flake configuration
├── flake.lock         # Nix dependency lock file
└── Makefile           # Main commands
```

## Managed Configurations

### Editors & Development

- **Neovim**: Main editor (lazy.nvim + numerous plugins)

### Terminal & Shell

- **Wezterm**: Main terminal emulator
- **Zsh**: Main shell (Powerlevel10k theme)
- **Tmux**: Terminal multiplexer

### Git Related

- **Git**: Version control configuration
- **Lazygit**: Git TUI client
- **GitHub CLI**: GitHub operations tool

### Other Tools

- **Karabiner-Elements**: Keyboard customization
- **Hammerspoon**: macOS automation
- **AeroSpace**: Window manager
- **Raycast**: Launcher
- **SKK**: Japanese input method
- **Mise**: Runtime version management

## Commands

| Command     | Description                                               |
| ----------- | --------------------------------------------------------- |
| `make init` | Install Xcode Command Line Tools and essentials (macOS)   |
| `make link` | Create symlinks for configuration files in home directory |

## License

MIT
