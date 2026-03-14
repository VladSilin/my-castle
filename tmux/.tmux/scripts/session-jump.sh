#!/bin/bash
# Session-scoped pane jump: pick session → pick command → jump to first match
# Called from tmux bind g via display-popup
source "$(dirname "$0")/lib.sh"

sess=$(tmux list-sessions -F '#S' | fzf --reverse --header 'Pick session:') || exit 0
cmds=$(tmux list-panes -s -t "$sess" -F '#{pane_current_command}' | sort -u)
cmd=$(pick_command "$sess — pick command:" "$cmds") || exit 0

tmux list-panes -s -t "$sess" -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' \
  | grep " ${cmd}$" \
  | head -1 \
  | awk '{print $1}' \
  | xargs tmux switch-client -t
