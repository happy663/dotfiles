# =============================================================================
# Directory Navigation
# =============================================================================

# -----------------------------------------------------------------------------
# Recent Directories
# -----------------------------------------------------------------------------
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# Notify Neovim's built-in terminal of the current shell directory.
function _nvim_osc7_cwd() {
  [[ -n "$NVIM" ]] || return
  printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
}
add-zsh-hook precmd _nvim_osc7_cwd

# -----------------------------------------------------------------------------
# Zoxide (Commented out)
# -----------------------------------------------------------------------------
eval "$(zoxide init zsh)"
eval "$(zoxide init zsh --cmd cd)"

# -----------------------------------------------------------------------------
# Auto ls after cd (Commented out)
# -----------------------------------------------------------------------------
case "${OSTYPE:-darwin}" in
  darwin*)
    export CLICOLOR=1
    function chpwd() { ls -A -G -F }
    ;;
  linux*)
    function chpwd() { ls -A -F --color=auto }
    ;;
esac
