# =============================================================================
# Environment Variables
# =============================================================================
# Load Home Manager session variables (PATH and environment variables)
# All static environment variables are managed in ~/.config/nix/home-manager/common.nix
# NOTE: Unset the flag to allow re-sourcing after home-manager switch
unset __HM_SESS_VARS_SOURCED
[ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ] && source ~/.nix-profile/etc/profile.d/hm-session-vars.sh

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
# Dynamic Settings
# -----------------------------------------------------------------------------
# Load Local Environment Variables
if [[ -f ~/.config/nix/home-manager/.env ]]; then
  source ~/.config/nix/home-manager/.env
  alias ssm="make -C $SSM_SCRIPT_PATH clean session"
fi
