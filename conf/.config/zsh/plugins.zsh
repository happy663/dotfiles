# =============================================================================
# Plugin Management
# =============================================================================

# -----------------------------------------------------------------------------
# Zinit Plugin Manager
# -----------------------------------------------------------------------------
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
if [ -n "$_comps" ]; then
  _comps[zinit]=_zinit
fi

# -----------------------------------------------------------------------------
# Powerlevel10k Instant Prompt
# -----------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------------------------------------------------------
# Zinit Plugins
# -----------------------------------------------------------------------------
zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light mollifier/anyframe
zinit light zsh-users/zsh-completions

# -----------------------------------------------------------------------------
# Powerlevel10k Configuration
# -----------------------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
