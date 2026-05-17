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

if [[ -n $ZENO_LOADED ]]; then # ここに任意のZLEの記述を行う
  bindkey " " zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion
  bindkey '^x^p' zeno-insert-snippet

  bindkey '^x ' zeno-insert-space # zenoを発動させないでSpace
  bindkey '^x^m' accept-line # zenoを発動させないでaccept

  # bindkey '^g' zeno-ghq-cd
fi

# -----------------------------------------------------------------------------
# Custom History Selection (zeno-history-selectionの代替)
# -----------------------------------------------------------------------------
function custom-history-selection() {
  local selection
  selection=$(builtin history -r 1 | fzf \
    --reverse \
    --height 50% \
    --no-sort \
    --exact \
    --no-multi \
    --query="$LBUFFER" \
    --prompt="History> " \
    --with-nth=2..)
  
  if [[ -n "$selection" ]]; then
    local history_index=${${=selection}[1]}
    if [[ -n "$history_index" ]]; then
      zle vi-fetch-history -n "$history_index"
    fi
  fi
  zle reset-prompt
}
zle -N custom-history-selection
bindkey '^r' custom-history-selection


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

function ghq-list() {
  local selected=$(ghq list | fzf --reverse --height 50% --preview 'ls -la $(ghq root)/{}')
  if [[ -n "$selected" ]]; then
    BUFFER="cd $(ghq root)/${selected}"
    zle accept-line
  fi
  zle reset-prompt
}

zle -N ghq-list
bindkey '^g' ghq-list


# -----------------------------------------------------------------------------
# vim-tmux-navigator: バッファ空判定によるシームレスなペイン移動
# バッファが空の時はtmuxペイン移動、入力中は通常のreadline操作
# -----------------------------------------------------------------------------
function _tmux_navigate_or() {
  local pane_dir=$1
  local fallback=$2
  if [[ -n $TMUX && -z $BUFFER ]]; then
    tmux select-pane $pane_dir
  else
    zle $fallback
  fi
}

function _navigate_left()  { _tmux_navigate_or -L backward-delete-char }
function _navigate_right() {
  if [[ -n $TMUX && -z $BUFFER ]]; then
    tmux select-pane -R
  else
    zle -I
    clear
    zle reset-prompt
  fi
}
function _navigate_down()  { _tmux_navigate_or -D accept-line }
function _navigate_up()    { _tmux_navigate_or -U kill-line }

zle -N _navigate_left
zle -N _navigate_right
zle -N _navigate_down
zle -N _navigate_up

bindkey '^h' _navigate_left
bindkey '^l' _navigate_right
bindkey '^j' _navigate_down
bindkey '^k' _navigate_up
