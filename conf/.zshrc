# .zshrcの一番始めに記載すること
if [ "$ZSHRC_PROFILE" != "" ]; then
  zmodload zsh/zprof && zprof > /dev/null
fi
# =============================================================================
# Zsh Configuration
# Managed by dotfiles repository
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
# zinit light zsh-users/zsh-syntax-highlighting
# zinit light zsh-users/zsh-autosuggestions
# zinit light mollifier/anyframe
# zinit light zsh-users/zsh-completions
#
# # -----------------------------------------------------------------------------
# # Completion System
# # -----------------------------------------------------------------------------
# autoload -Uz compinit && compinit
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# zstyle ':completion:*:default' menu select=1
#
# # -----------------------------------------------------------------------------
# # Recent Directories
# # -----------------------------------------------------------------------------
# autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
# add-zsh-hook chpwd chpwd_recent_dirs
#
# # -----------------------------------------------------------------------------
# # Key Bindings
# # -----------------------------------------------------------------------------
# bindkey '^xb' anyframe-widget-cdr
# bindkey '^xr' anyframe-widget-execute-history
# bindkey '^x^b' anyframe-widget-checkout-git-branch
# bindkey -e
#
# # -----------------------------------------------------------------------------
# # Mise
# # -----------------------------------------------------------------------------
# eval "$(mise activate zsh)"
#
# # -----------------------------------------------------------------------------
# # Zoxide
# # -----------------------------------------------------------------------------
# eval "$(zoxide init zsh)"
#
# # -----------------------------------------------------------------------------
# # Auto ls after cd
# # -----------------------------------------------------------------------------
# case "${OSTYPE:-darwin}" in
#   darwin*)
#     export CLICOLOR=1
#     function chpwd() { ls -A -G -F }
#     ;;
#   linux*)
#     function chpwd() { ls -A -F --color=auto }
#     ;;
# esac
#
# # -----------------------------------------------------------------------------
# # Prompt Configuration (Shell Integration)
# # -----------------------------------------------------------------------------
# _prompt_executing=""
# function __prompt_precmd() {
#   local ret="$?"
#   if test "$_prompt_executing" != "0"
#   then
#     _PROMPT_SAVE_PS1="$PS1"
#     _PROMPT_SAVE_PS2="$PS2"
#     PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
#     PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
#   fi
#   if test "$_prompt_executing" != ""
#   then
#     printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
#   fi
#   printf "\033]133;A;cl=m;aid=%s\007" "$$"
#   _prompt_executing=0
# }
# function __prompt_preexec() {
#   PS1="$_PROMPT_SAVE_PS1"
#   PS2="$_PROMPT_SAVE_PS2"
#   printf "\033]133;C;\007"
#   _prompt_executing=1
# }
# preexec_functions+=(__prompt_preexec)
# precmd_functions+=(__prompt_precmd)
#
# # -----------------------------------------------------------------------------
# # Environment Variables
# # -----------------------------------------------------------------------------
# export GOPATH=$HOME/go
# export PATH=$PATH:$HOME/.local/bin
# export PATH=$PATH:$HOME/.config/wezterm
# export PATH="$PATH:/opt/homebrew/bin"
# export PATH="$PATH:/usr/local/bin"
# export PATH=~/.nix-profile/bin:$PATH
# export XDG_CONFIG_HOME="$HOME/.config"
# export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
# export PATH="$PATH:$HOME/src/github.com/wachikun/yaskkserv2/target/release"
# export LIMA_HOME="$HOME/.colima_lima"
#
# # Coursier Java
# eval "$(coursier java --jvm temurin:17 --env)"
#
# # -----------------------------------------------------------------------------
# # OS-Specific Settings
# # -----------------------------------------------------------------------------
# if [[ "$OSTYPE" == "darwin"* ]]; then
#   export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib $LDFLAGS"
#   export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include $CPPFLAGS"
#   export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
# elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
#   alias pbcopy='xsel --clipboard --input'
# fi
#
# # -----------------------------------------------------------------------------
# # Neovim Remote Settings
# # -----------------------------------------------------------------------------
# if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
#   alias nvim=nvr -cc split --remote-wait +'set bufhidden=wipe'
#   export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
#   export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
# fi
#
# # -----------------------------------------------------------------------------
# # Custom Functions
# # -----------------------------------------------------------------------------
#
# # yazi - file manager integration
# function y() {
#   local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
#   yazi "$@" --cwd-file="$tmp"
#   if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#     builtin cd -- "$cwd"
#   fi
#   rm -f -- "$tmp"
# }
#
# # fkill - fuzzy process kill
# function fkill() {
#   local pid
#   pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
#   if [ "x$pid" != "x" ]
#   then
#     echo $pid | xargs kill -9
#   fi
# }
#
# # ghcr - create GitHub repo and clone with ghq
# function ghcr() {
#   gh repo create "$@"
#   ghq get "git@github.com:happy663/$1.git"
# }
#
# # movehere - move file from Downloads (or specified dir) to current dir
# function movehere() {
#   local search_dir
#   search_dir="${1:-$HOME/Downloads}"
#   mv "$search_dir/$(ls -t -r "$search_dir" | fzf)" .
# }
#
# # -----------------------------------------------------------------------------
# # Shell Aliases
# # -----------------------------------------------------------------------------
# alias g='cd $(ghq root)/$(ghq list | peco)'
# alias cat='bat'
# alias find='fd'
# alias '..'='cd ..'
# alias '...'='cd ../..'
# alias '....'='cd ../../..'
# alias ghb='gh browse'
# alias ghpc='gh pr checks'
# alias ghprc='gh pr create'
# alias relogin='exec $SHELL -l'
# alias gc='ghq get'
# alias po='poetry'
# alias py='python3'
# alias de='docker exec -it $(docker ps | peco | cut -d " " -f 1) /bin/bash'
# alias bat='bat'
# alias rg='rg'
# alias fzf='fzf'
# alias alert='terminal-notifier -message'
#
# # -----------------------------------------------------------------------------
# # History Configuration
# # -----------------------------------------------------------------------------
# HISTSIZE=1000
# SAVEHIST=1000
# HISTFILE=$HOME/.zsh_history
# setopt HIST_IGNORE_DUPS
# setopt SHARE_HISTORY
#
# -----------------------------------------------------------------------------
# Powerlevel10k Configuration
# -----------------------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#
# # -----------------------------------------------------------------------------
# # AWS Session Token TTL
# # -----------------------------------------------------------------------------
# export AWS_SESSION_TOKEN_TTL=12h
#
# # -----------------------------------------------------------------------------
# # Load Local Environment Variables
# # -----------------------------------------------------------------------------
# if [[ -f ~/.config/nix/home-manager/.env ]]; then
#   source ~/.config/nix/home-manager/.env
#   alias ssm="make -C $SSM_SCRIPT_PATH clean session"
# fi
#
#
# function zsh-profiler() {
#   ZSHRC_PROFILE=1 zsh -i -c zprof
# }
#
# # -----------------------------------------------------------------------------
# # Neovim Auto-Restart Function
# # -----------------------------------------------------------------------------
# # nvimを起動し、:Restartコマンド使用時に自動的に再起動する
# function nvim-restart() {
#   local restart_marker="$HOME/.local/share/nvim/possession/restart.json"
#   
#   # nvimを起動
#   command nvim "$@"
#   
#   # restart.jsonが存在する限り再起動を繰り返す
#   while [[ -f "$restart_marker" ]]; do
#     echo "Restarting nvim..."
#     command nvim "$@"
#   done
# }
#
# # nコマンドをnvim-restart関数にエイリアス
# alias n='nvim-restart'


function zsh-startuptime() {
  local total_msec=0
  local msec
  local i
  for i in $(seq 1 10); do
    msec=$((TIMEFMT='%mE'; time zsh -i -c exit) 2>/dev/stdout >/dev/null)
    msec=$(echo $msec | tr -d "ms")
    echo "${(l:2:)i}: ${msec} [ms]"
    total_msec=$(( $total_msec + $msec ))
  done
  local average_msec
  average_msec=$(( ${total_msec} / 10 ))
  echo "\naverage: ${average_msec} [ms]"
}


function zsh-startuptime-slower-than-default() {
  local time_rc
  time_rc=$((TIMEFMT="%mE"; time zsh -i -c exit) &> /dev/stdout)
  # time_norc=$((TIMEFMT="%mE"; time zsh -df -i -c exit) &> /dev/stdout)
  # compinit is slow
  local time_norc
  time_norc=$((TIMEFMT="%mE"; time zsh -df -i -c "autoload -Uz compinit && compinit -C; exit") &> /dev/stdout)
  echo "my zshrc: ${time_rc}\ndefault zsh: ${time_norc}\n"

  local result
  result=$(scale=3 echo "${time_rc%ms} / ${time_norc%ms}" | bc)
  echo "${result}x slower your zsh than the default."
}

function zsh-profiler() {
  ZSHRC_PROFILE=1 zsh -i -c zprof
}


zmodload zsh/zprof



