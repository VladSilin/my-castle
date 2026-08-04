#!/usr/bin/env bash
# Session-scoped window jump: pick session → pick window (by name) → jump to it
# Called from tmux bind g via display-popup
#
# Keyed off window_name rather than pane_current_command: with one agent
# process per pane, pane_current_command is the same for every window
# (e.g. claude.exe), so it never disambiguates. window_name carries the
# per-window identity instead (manually renamed windows keep their name;
# automatic-rename only overwrites windows that haven't been renamed).
source "$(dirname "$0")/lib.sh"

sessions=$(tmux list-sessions -F '#S')
sess=$(pick_command 'Pick session:' "$sessions") || exit 0
names=$(tmux list-windows -t "$sess" -F '#{window_name}' | sort | uniq -c | awk '{print $2 " (" $1 ")"}')
count=$(echo "$names" | wc -l | tr -d ' ')
if [ "$count" = "1" ]; then
  name=$(echo "$names" | sed 's/ ([0-9]*)$//')
else
  enable_global=1 name=$(pick_command "$sess — pick window (⌥⏎=all):" "$names") || exit 0
  name=$(echo "$name" | sed 's/ ([0-9]*)$//')
fi

# alt-enter: show all panes across windows with that name within the session
if [[ "$name" == GLOBAL:* ]]; then
  name="${name#GLOBAL:}"
  name=$(echo "$name" | sed 's/^\[.\] //' | sed 's/ ([0-9]*)$//')
  matches=$(tmux list-panes -s -t "$sess" -F $'#{session_name}:#{window_index}.#{pane_index}\t#{window_name}\t#{pane_current_command}' \
    | awk -F'\t' -v n="$name" '$2 == n' | while IFS=$'\t' read -r pane wname pcmd; do
      if [ "$pcmd" = "$AGENT_PROC" ] && is_awaiting "$pane"; then
        echo "$pane $wname $AWAITING_ICON_ANSI"
      else
        echo "$pane $wname"
      fi
    done)
  count=$(echo "$matches" | wc -l | tr -d ' ')
  if [ "$count" = "1" ]; then
    echo "$matches" | awk '{print $1}' | xargs tmux switch-client -t
  else
    echo "$matches" | fzf --reverse --header "$name panes ($sess):" \
      --ansi --preview 'tmux capture-pane -e -t {1} -p | grep -v "^$"' --preview-window=right,70%,follow \
      | awk '{print $1}' | xargs tmux switch-client -t
  fi
  exit 0
fi

tmux list-panes -s -t "$sess" -F $'#{session_name}:#{window_index}.#{pane_index}\t#{window_name}' \
  | awk -F'\t' -v n="$name" '$2 == n' \
  | head -1 \
  | awk -F'\t' '{print $1}' \
  | xargs tmux switch-client -t
