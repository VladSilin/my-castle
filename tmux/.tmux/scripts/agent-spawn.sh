#!/bin/bash
# Open a new window running an agent with consistent naming
# Called from tmux bind C via run-shell
source "$(dirname "$0")/lib.sh"

n=$(tmux list-windows -F "#{window_name}" | grep -c "^${AGENT_CMD}")
tmux command-prompt -p "Window name:" -I "${AGENT_CMD}-$((n + 1))" \
  "new-window -n '%%' ${AGENT_CMD} ; set-option -w automatic-rename off"
