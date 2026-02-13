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

# ziエイリアスを削除（zoxideのziコマンドに譲る）
unalias zi 2>/dev/null

# zinitには別のエイリアスを設定
alias zin='zinit'

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
zinit light mollifier/anyframe
zinit light zsh-users/zsh-completions

# Load zeno.zsh before autosuggestions so that zeno widgets get wrapped properly
zinit ice lucid depth"1" blockf
zinit light yuki-yano/zeno.zsh

# zeno-auto-snippet-and-accept-lineをCLEAR_WIDGETSに追加
# これによりEnter時にautosuggestionsの提案がクリアされる
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(zeno-auto-snippet-and-accept-line)

# Load autosuggestions after zeno.zsh to wrap zeno-auto-snippet-and-accept-line
zinit light zsh-users/zsh-autosuggestions

# Load syntax-highlighting last to properly highlight all commands
# zinit light zsh-users/zsh-syntax-highlighting
zinit light zdharma-continuum/fast-syntax-highlighting


# -----------------------------------------------------------------------------
# Powerlevel10k Configuration
# -----------------------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh



