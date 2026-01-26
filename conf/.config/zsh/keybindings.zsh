# =============================================================================
# Key Bindings
# =============================================================================

# -----------------------------------------------------------------------------
# Anyframe Key Bindings (Commented out)
# -----------------------------------------------------------------------------
# bindkey '^xb' anyframe-widget-cdr
# bindkey '^xr' anyframe-widget-execute-history
# bindkey '^x^b' anyframe-widget-checkout-git-branch

# -----------------------------------------------------------------------------
# Emacs Mode (Commented out)
# -----------------------------------------------------------------------------
bindkey -e

if [[ -n $ZENO_LOADED ]]; then
  # ここに任意のZLEの記述を行う

  bindkey " " zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion
  bindkey '^x^p' zeno-insert-snippet

  bindkey '^x ' zeno-insert-space # zenoを発動させないでSpace
  bindkey '^x^m' accept-line # zenoを発動させないでaccept

  # 入れると便利
  bindkey '^r' zeno-history-selection
  bindkey '^x^f' zeno-ghq-cd
fi


# -----------------------------------------------------------------------------
# Zoxide Key Binding
# -----------------------------------------------------------------------------
# Ctrl+sでzoxideのインタラクティブモードを起動
function zoxide-widget() {
  local result=$(zoxide query -i)
  if [[ -n "$result" ]]; then
    BUFFER="cd ${(q)result}"
    zle accept-line
  fi
}
zle -N zoxide-widget
bindkey '^s' zoxide-widget





