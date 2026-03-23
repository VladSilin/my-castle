#!/bin/bash
# Two-step pane finder: pick command type → pick pane with preview
# Called from tmux bind m via display-popup
# Marks agent panes with ⧑ if awaiting input (sentinel absent)
source "$(dirname "$0")/lib.sh"

cmds=$(tmux list-panes -a -F '#{pane_current_command}' | sort -u)
cmd=$(pick_command "Pick command:" "$cmds") || exit 0

matches=$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{window_name} #{pane_current_command}' \
  | grep " ${cmd}$" | awk '{print $1, $2, $3}' | while read pane name pcmd; do
    if [ "$pcmd" = "$AGENT_CMD" ] && is_awaiting "$pane"; then
      echo "$pane $name $AWAITING_ICON"
    else
      echo "$pane $name"
    fi
  done)

count=$(echo "$matches" | wc -l | tr -d ' ')
if [ "$count" = "1" ]; then
  echo "$matches" | awk '{print $1}' | xargs tmux switch-client -t
else
  echo "$matches" | fzf --reverse --header "$cmd panes:" --ansi --preview 'tmux capture-pane -e -t {1} -p | grep -v "^$"' --preview-window=right,70%,follow \
    | awk '{print $1}' | xargs tmux switch-client -t
fi
