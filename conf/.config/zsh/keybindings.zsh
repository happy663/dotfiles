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
  local selected=$(ghq list | fzf --reverse --height 50%)
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
# 外側のマルチプレクサ（tmux / herdr）のペインを移る。どちらの中でもなければ 1 を返す。
# herdr は新しいペインから TMUX を外すので、両方が同時に立つことはない（issue #351）。
function _mux_select_pane() {
  local dir=$1  # L / D / U / R
  if [[ -n $TMUX ]]; then
    tmux select-pane -$dir
    return 0
  fi
  if [[ $HERDR_ENV == 1 && -n $HERDR_PANE_ID ]]; then
    local -A names=(L left D down U up R right)
    herdr pane focus --direction ${names[$dir]} --pane $HERDR_PANE_ID >/dev/null 2>&1 &!
    return 0
  fi
  return 1
}

function _tmux_navigate_or() {
  local pane_dir=$1
  local fallback=$2
  if [[ -z $BUFFER ]] && _mux_select_pane ${pane_dir#-}; then
    return
  fi
  zle $fallback
}

function _navigate_left()  { _tmux_navigate_or -L backward-delete-char }
function _navigate_right() {
  if [[ -z $BUFFER ]] && _mux_select_pane R; then
    return
  else
    zle -I
    clear
    zle reset-prompt
  fi
}
function _navigate_down()  { _tmux_navigate_or -D accept-line }
function _navigate_up()    { _tmux_navigate_or -U kill-line }
function _resize_or_end_of_line() {
  if [[ -n $TMUX && -z $BUFFER ]]; then
    tmux switch-client -T resize
  else
    zle end-of-line
  fi
}

# herdr-nvim-nav の目印（issue #351）。herdr 側のプラグインは、ペインごとの目印ファイルに
# 生きている PID があればキーをそのペインに渡し、なければ herdr がペインを移る。
# zsh もプロンプトを出している間だけ目印を置き、C-h/j/k/l を受け取って上の判定（入力が空なら移動）を使う。
# コマンドの実行中（lazygit など）は目印を消し、herdr にペインを移らせる。nvim は起動時に自分で目印を書く。
# nvim の :terminal の中の zsh（$NVIM がある）は、外側の nvim の目印を壊さないよう何もしない。
if [[ $HERDR_ENV == 1 && -n $HERDR_PANE_ID && -z $NVIM ]]; then
  zmodload -F zsh/files b:zf_rm b:zf_mkdir 2>/dev/null
  _herdr_nav_marker="${XDG_CACHE_HOME:-$HOME/.cache}/herdr/nvim-panes/$HERDR_PANE_ID"
  function _herdr_nav_claim() {
    [[ -d ${_herdr_nav_marker:h} ]] || zf_mkdir -p ${_herdr_nav_marker:h}
    print -r -- $$ >| $_herdr_nav_marker
  }
  function _herdr_nav_release() {
    [[ -f $_herdr_nav_marker && "$(<$_herdr_nav_marker)" == $$ ]] && zf_rm -f $_herdr_nav_marker
    return 0
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _herdr_nav_claim
  add-zsh-hook preexec _herdr_nav_release
  add-zsh-hook zshexit _herdr_nav_release
fi

zle -N _navigate_left
zle -N _navigate_right
zle -N _navigate_down
zle -N _navigate_up
zle -N _resize_or_end_of_line

bindkey '^h' _navigate_left
bindkey '^l' _navigate_right
bindkey '^j' _navigate_down
bindkey '^k' _navigate_up
bindkey '^e' _resize_or_end_of_line
