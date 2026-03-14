#!/bin/bash
# Session-scoped pane jump: pick session → pick command → jump to first match
# Called from tmux bind g via display-popup
source "$(dirname "$0")/lib.sh"

sessions=$(tmux list-sessions -F '#S')
sess=$(pick_command 'Pick session:' "$sessions") || exit 0
cmds=$(tmux list-panes -s -t "$sess" -F '#{pane_current_command}' | sort -u)
count=$(echo "$cmds" | wc -l | tr -d ' ')
if [ "$count" = "1" ]; then
  cmd="$cmds"
else
  cmd=$(pick_command "$sess — pick command:" "$cmds") || exit 0
fi

tmux list-panes -s -t "$sess" -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' \
  | grep " ${cmd}$" \
  | head -1 \
  | awk '{print $1}' \
  | xargs tmux switch-client -t
