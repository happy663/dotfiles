#!/usr/bin/env bash

# Render all sessions as a FIXED vertical list in the tmux status lines
# (one session per line, creation order). The current session is highlighted
# live via #{==:#{client_session},NAME} so switching only moves the highlight —
# the list order never changes (vertical equivalent of the window tab bar).
#
# The current session's line also shows the window list.
# tmux supports at most 5 status lines, so the list is capped at 5.
#
# Triggered by tmux hooks on session create/close/rename (see tmux.conf).

set -euo pipefail

MAX=5

# Sessions in creation order (matches switch-session.sh ordering).
sessions=()
while IFS= read -r name; do
    sessions+=("$name")
done < <(tmux list-sessions -F '#{session_created} #{session_name}' | sort -n | awk '{print $2}')

n=${#sessions[@]}
[ "$n" -eq 0 ] && exit 0

lines=$n
[ "$lines" -gt "$MAX" ] && lines=$MAX

# Window list for the current session's line (keeps existing agent-status icons).
win='#{W:#[push-default]#{T:window-status-format}#[pop-default],#[push-default]#{T:window-status-current-format}#[pop-default]}'

# Column alignment: pad each session name to the longest name's width so the
# window-list column starts at the same position regardless of which session
# is current.
maxlen=0
for name in "${sessions[@]}"; do
    len=${#name}
    [ "$len" -gt "$maxlen" ] && maxlen=$len
done

for ((i = 0; i < lines; i++)); do
    name=${sessions[$i]}
    pad_total=$((maxlen - ${#name}))
    pad_left=$(((pad_total + 1) / 2))
    pad_right=$((pad_total - pad_left))
    padded="$(printf '%*s' "$pad_left" '')${name}$(printf '%*s' "$pad_right" '')"
    # Commas inside our own #[...] must be escaped as #, because they sit at the
    # top level of the #{?cond,true,false} conditional.
    cur="#[bg=#1a1b26#,fg=#bb9af7]#[bg=#bb9af7#,fg=#1a1b26#,bold] ${padded} #[bg=#1a1b26#,fg=#bb9af7]#[default] ${win}"
    oth="#[fg=#c0caf5]  ${padded} "
    fmt="#[align=left]#{?#{==:#{client_session},${name}},${cur},${oth}}"
    tmux set-option -g "status-format[$i]" "$fmt"
done

# tmux accepts numeric values for two or more status lines, but a single line
# must be specified as `on` rather than `1`.
if [ "$lines" -eq 1 ]; then
    tmux set-option -g status on
else
    tmux set-option -g status "$lines"
fi
