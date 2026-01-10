# =============================================================================
# Environment Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Environment
# -----------------------------------------------------------------------------
export GOPATH=$HOME/go
export XDG_CONFIG_HOME="$HOME/.config"
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
export LIMA_HOME="$HOME/.colima_lima"

# -----------------------------------------------------------------------------
# PATH Configuration
# -----------------------------------------------------------------------------
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.config/wezterm
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:/usr/local/bin"
export PATH=~/.nix-profile/bin:$PATH
export PATH="$PATH:$HOME/src/github.com/wachikun/yaskkserv2/target/release"

# -----------------------------------------------------------------------------
# Prompt Configuration / Shell Integration (Commented out)
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Coursier Java (Commented out)
# -----------------------------------------------------------------------------
# eval "$(coursier java --jvm temurin:17 --env)"

# -----------------------------------------------------------------------------
# OS-Specific Settings (Commented out)
# -----------------------------------------------------------------------------
# if [[ "$OSTYPE" == "darwin"* ]]; then
#   export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib $LDFLAGS"
#   export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include $CPPFLAGS"
#   export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
# elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
#   alias pbcopy='xsel --clipboard --input'
# fi

# -----------------------------------------------------------------------------
# Neovim Remote Settings (Commented out)
# -----------------------------------------------------------------------------
if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
  alias nvim=nvr -cc split --remote-wait +'set bufhidden=wipe'
  export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
fi

# -----------------------------------------------------------------------------
# AWS Session Token TTL (Commented out)
# -----------------------------------------------------------------------------
export AWS_SESSION_TOKEN_TTL=24h


# Load Local Environment Variables (Commented out)
# -----------------------------------------------------------------------------
if [[ -f ~/.config/nix/home-manager/.env ]]; then
  source ~/.config/nix/home-manager/.env
  alias ssm="make -C $SSM_SCRIPT_PATH clean session"
fi

export COLIMA_HOME=$HOME/.local/share/colima 
export DOCKER_HOST="unix://${COLIMA_HOME}/default/docker.sock"
