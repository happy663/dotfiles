# Fig pre block. Keep at the top of this file.
#[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
#
#
#
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n] confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{32} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
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


autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs


## コマンド補完
zinit ice wait'0'; 
autoload -Uz compinit && compinit
## 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## 補完候補を一覧表示したとき、Tabや矢印で選択できるようにする
zstyle ':completion:*:default' menu select=1 

bindkey '^xb' anyframe-widget-cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
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

export GOPATH=$HOME/go
export PATH=$PATH:$HOME/.local/bin

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias gc='ghq get'


[ -f "/Users/toyama/.ghcup/env" ] && source "/Users/toyama/.ghcup/env" # ghcup-env

if [[ "$OSTYPE" == "darwin"* ]]; then
    export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib $LDFLAGS"
    export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include $CPPFLAGS"
    export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    export LDFLAGS="-L/home/linuxbrew/.linuxbrew/opt/zlib/lib \
    -L/home/linuxbrew/.linuxbrew/opt/openssl@1.1/lib \
    -L/home/linuxbrew/.linuxbrew/opt/readline/lib \
    -L/home/linuxbrew/.linuxbrew/opt/libffi/lib \
    -L/home/linuxbrew/.linuxbrew/opt/ncurses/lib \
    -L/home/linuxbrew/.linuxbrew/opt/bzip2/lib $LDFLAGS"

    export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/zlib/include \
    -I/home/linuxbrew/.linuxbrew/opt/openssl@1.1/include \
    -I/home/linuxbrew/.linuxbrew/opt/readline/include \
    -I/home/linuxbrew/.linuxbrew/opt/libffi/include \
    -I/home/linuxbrew/.linuxbrew/opt/ncurses/include \
    -I/home/linuxbrew/.linuxbrew/opt/bzip2/include $CPPFLAGS"

    export PKG_CONFIG_PATH="/home/linuxbrew/.linuxbrew/opt/zlib/lib/pkgconfig:\
    /home/linuxbrew/.linuxbrew/opt/openssl@1.1/lib/pkgconfig:\
    /home/linuxbrew/.linuxbrew/opt/readline/lib/pkgconfig:\
    /home/linuxbrew/.linuxbrew/opt/libffi/lib/pkgconfig:\
    /home/linuxbrew/.linuxbrew/opt/ncurses/lib/pkgconfig:\
    /home/linuxbrew/.linuxbrew/opt/bzip2/lib/pkgconfig:\
    $PKG_CONFIG_PATH"

    alias pbcopy='xsel --clipboard --input'
    #export DISPLAY=`ip route | grep 'default via' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`:0
fi

HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS


PATH=~/.console-ninja/.bin:$PATH

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

alias ghb="gh browse"
alias ghpc="gh pr checks"
alias ghprc="gh pr create"
eval "$(mise activate zsh)"
alias relogin='exec $SHELL -l'
alias po='poetry'
alias py='python3'



export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.config/wezterm
export PATH="$PATH:/opt/homebrew/bin"


export PATH="$PATH:/Users/toyama/src/github.com/wachikun/yaskkserv2/target/release"

export PATH="$PATH:$HOME/.roswell/bin"

export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"

ghcr() {
  gh repo create "$@" # 全引数をそのままghに渡す
  ghq get "git@github.com:happy663/$1.git" # 最初の引数のみ使用
  nvim "/Users/toyama/src/github.com/happy663/$1"
}


alias n='nvim'

if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    alias nvim=nr -cc split --remote-wait +'set bufhidden=wipe'
fi

if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    alias nvim=nvr -cc split --remote-wait +'set bufhidden=wipe'
    export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
    export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
fi

# ~/.zshrc
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

alias movehere='function _movehere(){ SEARCH_DIR=${1:-~/Downloads}; mv "$SEARCH_DIR/$(ls -t -r "$SEARCH_DIR" | fzf)" .; }; _movehere'

# プロセスをkill
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}


# FindItFaster の依存関係へのパスを追加
export PATH=$PATH:/usr/local/bin
alias bat=bat
alias rg=rg
alias fzf=fzf

export PATH=~/.nix-profile/bin:$PATH
