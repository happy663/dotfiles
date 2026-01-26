# =============================================================================
# Zsh Configuration
# Managed by dotfiles repository
# =============================================================================
# 
# Configuration files are split into modular files for better organization:
#   ~/.config/zsh/init.zsh          - Profiling and initialization
#   ~/.config/zsh/plugins.zsh       - Plugin management (zinit)
#   ~/.config/zsh/environment.zsh   - Environment variables and PATH
#   ~/.config/zsh/navigation.zsh    - Directory navigation settings
#   ~/.config/zsh/completion.zsh    - Completion settings
#   ~/.config/zsh/history.zsh       - History configuration
#   ~/.config/zsh/keybindings.zsh   - Key bindings
#   ~/.config/zsh/aliases.zsh       - Shell aliases
#   ~/.config/zsh/functions.zsh     - Custom functions
#
# =============================================================================

if [[ -t 0 ]]; then
  stty stop undef
  stty start undef
fi
# Source all configuration files
source ~/.config/zsh/init.zsh
source ~/.config/zsh/plugins.zsh
source ~/.config/zsh/environment.zsh
source ~/.config/zsh/navigation.zsh
source ~/.config/zsh/completion.zsh
source ~/.config/zsh/history.zsh
source ~/.config/zsh/keybindings.zsh
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/functions.zsh

