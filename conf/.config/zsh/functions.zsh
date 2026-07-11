# =============================================================================
# Custom Functions
# =============================================================================

# -----------------------------------------------------------------------------
# File Manager Integration (Commented out)
# -----------------------------------------------------------------------------
# yazi - file manager integration
# function y() {
#   local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
#   yazi "$@" --cwd-file="$tmp"
#   if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#     builtin cd -- "$cwd"
#   fi
#   rm -f -- "$tmp"
# }

# -----------------------------------------------------------------------------
# Process Management
# -----------------------------------------------------------------------------
# fkill - fuzzy process kill
function fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -9
  fi
}

# -----------------------------------------------------------------------------
# GitHub Functions
# -----------------------------------------------------------------------------
# ghcr - create GitHub repo and clone with ghq
function ghcr() {
  gh repo create "$@"
  ghq get "git@github.com:happy663/$1.git"
}

# -----------------------------------------------------------------------------
# File Operations
# -----------------------------------------------------------------------------
# movehere - move file from Downloads (or specified dir) to current dir
function movehere() {
  local search_dir
  search_dir="${1:-$HOME/Downloads}"
  mv "$search_dir/$(ls -t -r "$search_dir" | fzf)" .
}

# -----------------------------------------------------------------------------
# Neovim Auto-Restart Function
# -----------------------------------------------------------------------------
# nvimを起動し、:Restartコマンド使用時に自動的に再起動する
function nvim-restart() {
  local restart_marker="$HOME/.local/share/nvim/possession/restart.json"
  
  # nvimを起動
  command nvim "$@"
  
  # restart.jsonが存在する限り再起動を繰り返す
  while [[ -f "$restart_marker" ]]; do
    echo "Restarting nvim..."
    command nvim "$@"
  done
}

# nvim-view - open Neovim as an Oil file viewer with optional path
function nvim-view() {
  local target="${1:-.}"
  command nvim -c "let g:oil_view_mode= 1" -c "Oil --float --preview ${(q)target}"
}

# nvim-codex - open Neovim and run :AgentCodex with optional args
function nvim-codex() {
  local ex_cmd="AgentCodex"
  if (( $# > 0 )); then
    ex_cmd+=" ${(q)@}"
  fi
  command nvim -c "$ex_cmd"
}

function nvim-claude() {
  local ex_cmd="AgentClaude"
  if (( $# > 0 )); then
    ex_cmd+=" ${(q)@}"
  fi
  command nvim -c "$ex_cmd"
}

function nvim-claude-session() {
  command nvim -c "AgentClaudeSession"
}

function nvim-codex-session() {
  command nvim -c "AgentCodexSession"
}

function nvim-claude-codex() {
  local ex_cmd="AgentClaudeCodex"
  if (( $# > 0 )); then
    ex_cmd+=" ${(q)@}"
  fi
  command nvim -c "$ex_cmd"
}

function nvim-claude-pair() {
  local ex_cmd="AgentClaudePair"
  if (( $# > 0 )); then
    ex_cmd+=" ${(q)@}"
  fi
  command nvim -c "$ex_cmd"
}

function nvim-octo() {
  local ex_cmd="Octo"
  if (( $# > 0 )); then
    ex_cmd+=" $@"
  fi
  command nvim -c "$ex_cmd"
}

# nvim-guh - open Neovim and run :Guh with optional args
#   guh のターゲット (PR番号 / issue番号 / GitHub URL / owner/repo#N) を引数に取る。
#   # を含む slug もあるので ${(q)@} でクォートする。
#   :Guh を -c で即実行すると、noice が ui_attach する前に guh の progress ログが
#   cmdline に出て hit-enter (<CR>) を要求する。--cmd で VeryLazy (noice アタッチ後)
#   に :Guh を実行することで回避する (その分 dashboard が一瞬見えるので抑制も併用)。
function nvim-guh() {
  local ex_cmd="Guh"
  if (( $# > 0 )); then
    ex_cmd+=" ${(q)@}"
  fi
  # --cmd "let g:skip_dashboard=1": :Guh が VeryLazy 後に開くまでの間に dashboard
  #   (VimEnter) が一瞬表示されるのを抑制する (dashboard.lua の cond で参照)。
  command nvim --cmd "let g:skip_dashboard = 1" --cmd "autocmd User VeryLazy ++once lua vim.cmd('$ex_cmd')"
}

function nvim-octo-issues() {
  local ex_cmd="Octo issue list"
  if [[ -n "$1" ]]; then
    ex_cmd+=" $1"
  fi
  command nvim -c "$ex_cmd"
}

function nvim-octo-my-issues() {
  local ex_cmd="Octo issue list"
  if [[ -n "$1" ]]; then
    ex_cmd+=" $1"
  fi
  ex_cmd+=" assignee=happy663 states=OPEN"
  command nvim -c "$ex_cmd"
}

function nvim-octo-prs() {
  command nvim -c "Octo search author:@me is:open is:pr"
}

function nvim-octo-reviews() {
  command nvim -c "Octo search review-requested:@me is:open is:pr"
}

# -----------------------------------------------------------------------------
# Profiling and Performance Functions
# -----------------------------------------------------------------------------
# zsh-profiler - profile zsh startup
function zsh-profiler() {
  ZSHRC_PROFILE=1 zsh -i -c zprof
}

# zsh-startuptime - measure zsh startup time (10 iterations)
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

# zsh-startuptime-slower-than-default - compare startup time with default zsh
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

# -----------------------------------------------------------------------------
# Final Profiling Output
# -----------------------------------------------------------------------------
# zprofモジュールの読み込み（プロファイリングに必要）
zmodload zsh/zprof
