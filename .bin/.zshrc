# Fig pre block. Keep at the top of this file.
#[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
#
#
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n] confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# zinit ice pick"async.zsh" src"pure.zsh"

zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light mollifier/anyframe
zinit light zsh-users/zsh-completions

## コマンド補完
zinit ice wait'0'; 
autoload -Uz compinit && compinit
## 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## 補完候補を一覧表示したとき、Tabや矢印で選択できるようにする
zstyle ':completion:*:default' menu select=1 

bindkey '^xb' anyframe-widget-cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
bindkey '^xr' anyframe-widget-execute-history
bindkey '^x^b' anyframe-widget-checkout-git-branch



##色付け
alias ls="gls --color=auto"
alias cat=bat
alias g='cd $(ghq root)/$(ghq list | peco)'
alias find='fd'
alias de='docker exec -it $(docker ps | peco | cut -d " " -f 1) /bin/bash'
# ドットの数で表現
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export GOPATH=$HOME/go
export PATH=$PATH:$HOME/.local/bin

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias gc='ghq get'


[ -f "/Users/toyama/.ghcup/env" ] && source "/Users/toyama/.ghcup/env" # ghcup-env

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init --path)" # これを追記
eval "$(pyenv init -)"

export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"

export HISTSIZE=10000

alias vim="nvim"

PATH=~/.console-ninja/.bin:$PATH


export PATH="${PATH}:/Users/toyama/.local/lib/python3.10/site-packages"
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

export PATH="/opt/homebrew/opt/gcc/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"


# cdしたらlsする
case ${OSTYPE} in
    darwin*)
        #Mac用の設定
        export CLICOLOR=1
        function chpwd() { ls -A -G -F}
        ;;
    linux*)
        #Linux用の設定
        function chpwd() { ls -A -F --color=auto}
        ;;
esac
