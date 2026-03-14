#!/bin/bash
# Jump to first agent pane awaiting input, cycling through if already on one
# Called from tmux bind > via run-shell
source "$(dirname "$0")/lib.sh"

current=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')
awaiting=""

for p in $(list_agent_panes); do
  is_awaiting "$p" && awaiting="$awaiting $p"
done

awaiting=$(echo $awaiting | xargs)
[ -z "$awaiting" ] && tmux display-message "No agent panes awaiting action" && exit 0

in_list=0; next=""; pick_next=0; first=""
for p in $awaiting; do
  [ -z "$first" ] && first="$p"
  if [ "$pick_next" = "1" ]; then next="$p"; break; fi
  if [ "$p" = "$current" ]; then in_list=1; pick_next=1; fi
done

if [ "$in_list" = "0" ]; then tmux switch-client -t "$first"
elif [ -n "$next" ]; then tmux switch-client -t "$next"
else tmux switch-client -t "$first"
fi
