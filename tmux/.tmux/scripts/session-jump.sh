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
  enable_global=1 cmd=$(pick_command "$sess — pick command (⌥⏎=global):" "$cmds") || exit 0
fi

# ctrl+key: show all panes across all sessions for that command (like C-a m)
if [[ "$cmd" == GLOBAL:* ]]; then
  cmd="${cmd#GLOBAL:}"
  cmd=$(echo "$cmd" | sed 's/^\[.\] //')
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
    echo "$matches" | fzf --reverse --header "$cmd panes (all sessions):" \
      --ansi --preview 'tmux capture-pane -e -t {1} -p | grep -v "^$"' --preview-window=right,70%,follow \
      | awk '{print $1}' | xargs tmux switch-client -t
  fi
  exit 0
fi

tmux list-panes -s -t "$sess" -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' \
  | grep " ${cmd}$" \
  | head -1 \
  | awk '{print $1}' \
  | xargs tmux switch-client -t
