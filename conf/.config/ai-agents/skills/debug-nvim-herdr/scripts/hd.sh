#!/usr/bin/env bash
# debug-nvim-herdr: 隔離した herdr の名前付きセッションで実際の Neovim を動かすための薄いラッパー。
#
# 使い方:
#   hd.sh start <session> <cwd>        隔離 herdr を起動し、cwd でワークスペースを作る（pane id を表示）
#   hd.sh nvim  <session> [nvim args]  ペインで素の nvim を起動し、起動完了まで待つ
#   hd.sh text  <session> <text>       文字列をそのまま送る（Enter は送らない）
#   hd.sh keys  <session> <key>...     キーを送る（enter / escape / ctrl+c など）
#   hd.sh ex    <session> <command>    nvim の Ex コマンドを送って実行する（例: hd.sh ex s 'messages'）
#   hd.sh read  <session> [lines]      画面を読む（空行は除く）
#   hd.sh herdr <session> <args>...    このセッションに向けて herdr CLI をそのまま実行する
#   hd.sh attach-cmd <session>         ユーザーが画面を見るためのコマンドを表示する
#   hd.sh stop  <session>              nvim を閉じてセッションを止め、削除する
#
# 親 Neovim / tmux / Rex の環境変数を外して起動する。外さないと、zsh の nvim エイリアス（nvr）経由で
# 親 Neovim に split を開いてしまう（2026-11-11 に実際に起きた）。
set -euo pipefail

die() {
  echo "hd.sh: $*" >&2
  exit 1
}

herdr_bin() {
  if command -v herdr >/dev/null 2>&1; then
    command -v herdr
    return
  fi
  local dotfiles="${DOTFILES_DIR:-$HOME/src/github.com/happy663/dotfiles}"
  local out
  out=$(nix build --no-link --print-out-paths --inputs-from "$dotfiles" nixpkgs#herdr 2>/dev/null) ||
    die "herdr が見つからない（PATH にも nixpkgs にもない）"
  echo "$out/bin/herdr"
}

state_dir() { echo "/tmp/herdr-debug/$1"; }
socket_path() { echo "$HOME/.config/herdr/sessions/$1/herdr.sock"; }

# このセッション向けに herdr CLI を実行する
H() {
  local session="$1"
  shift
  HERDR_SOCKET_PATH="$(socket_path "$session")" "$HERDR" "$@"
}

pane_of() {
  local f
  f="$(state_dir "$1")/pane"
  [ -s "$f" ] || die "セッション $1 のペインが記録されていない（先に start する）"
  cat "$f"
}

cmd_start() {
  local session="$1" cwd="$2"
  [ -d "$cwd" ] || die "ディレクトリがない: $cwd"
  local sock
  sock="$(socket_path "$session")"
  [ -S "$sock" ] && die "セッション $session はすでにある。別名にするか stop する"
  mkdir -p "$(state_dir "$session")"
  env -u NVIM -u NVIM_LISTEN_ADDRESS -u TMUX -u TMUX_PANE \
    -u REX_SESSION -u REX_BLOCK -u REX_SERVER -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH \
    nohup "$HERDR" --session "$session" server >"$(state_dir "$session")/server.log" 2>&1 &
  local i
  for i in $(seq 1 50); do
    [ -S "$sock" ] && break
    sleep 0.2
  done
  [ -S "$sock" ] || die "サーバーが起動しない: $(state_dir "$session")/server.log を見る"
  H "$session" workspace create --cwd "$cwd" --label "$session" --no-focus >/dev/null
  local pane
  pane=$(H "$session" pane list | jq -r '.result.panes[0].pane_id')
  [ -n "$pane" ] && [ "$pane" != "null" ] || die "ペインが作れない"
  echo "$pane" >"$(state_dir "$session")/pane"
  # シェルの起動を待つ（プロンプトが出る前に送ると Enter が届かないことがある）
  sleep 2
  echo "session=$session pane=$pane socket=$sock"
}

cmd_nvim() {
  local session="$1"
  shift
  local pane ready
  pane=$(pane_of "$session")
  ready="$(state_dir "$session")/ready"
  : >"$ready"
  local args=""
  local a
  for a in "$@"; do
    args+=" $(printf '%q' "$a")"
  done
  H "$session" pane run "$pane" "env NVIM= NVIM_LISTEN_ADDRESS= command nvim +'lua vim.fn.writefile({\"ready\"}, \"$ready\")'$args"
  local i
  for i in $(seq 1 30); do
    [ -s "$ready" ] && break
    sleep 0.5
  done
  [ -s "$ready" ] || die "nvim の起動が確認できない（hd.sh read $session で画面を見る）"
  echo "nvim ready"
}

cmd_text() {
  local session="$1"
  shift
  H "$session" pane send-text "$(pane_of "$session")" "$*" >/dev/null
}

cmd_keys() {
  local session="$1"
  shift
  H "$session" pane send-keys "$(pane_of "$session")" "$@" >/dev/null
}

cmd_ex() {
  local session="$1"
  shift
  local pane
  pane=$(pane_of "$session")
  H "$session" pane send-keys "$pane" escape >/dev/null
  H "$session" pane send-text "$pane" ":$*" >/dev/null
  H "$session" pane send-keys "$pane" enter >/dev/null
}

cmd_read() {
  local session="$1" lines="${2:-}"
  local pane
  pane=$(pane_of "$session")
  if [ -n "$lines" ]; then
    H "$session" pane read "$pane" --source recent --lines "$lines" | grep -v '^[[:space:]]*$' || true
  else
    H "$session" pane read "$pane" --source visible | grep -v '^[[:space:]]*$' || true
  fi
}

cmd_stop() {
  local session="$1"
  local f
  f="$(state_dir "$session")/pane"
  if [ -s "$f" ] && [ -S "$(socket_path "$session")" ]; then
    local pane
    pane=$(cat "$f")
    H "$session" pane send-keys "$pane" escape >/dev/null 2>&1 || true
    H "$session" pane send-text "$pane" ":qa!" >/dev/null 2>&1 || true
    H "$session" pane send-keys "$pane" enter >/dev/null 2>&1 || true
    sleep 1
  fi
  "$HERDR" session stop "$session" >/dev/null 2>&1 || true
  sleep 0.5
  "$HERDR" session delete "$session" >/dev/null 2>&1 || true
  echo "stopped $session"
}

main() {
  [ $# -ge 2 ] || die "usage: hd.sh <start|nvim|text|keys|ex|read|herdr|attach-cmd|stop> <session> [args]"
  local cmd="$1" session="$2"
  shift 2
  case "$session" in
  *[!a-zA-Z0-9_-]*) die "セッション名は英数字・-・_ だけにする: $session" ;;
  esac
  HERDR="$(herdr_bin)"
  case "$cmd" in
  start)
    [ $# -ge 1 ] || die "usage: hd.sh start <session> <cwd>"
    cmd_start "$session" "$1"
    ;;
  nvim) cmd_nvim "$session" "$@" ;;
  text) cmd_text "$session" "$@" ;;
  keys) cmd_keys "$session" "$@" ;;
  ex) cmd_ex "$session" "$@" ;;
  read) cmd_read "$session" "$@" ;;
  herdr) H "$session" "$@" ;;
  attach-cmd) echo "$HERDR session attach $session" ;;
  stop) cmd_stop "$session" ;;
  *) die "unknown command: $cmd" ;;
  esac
}

main "$@"
