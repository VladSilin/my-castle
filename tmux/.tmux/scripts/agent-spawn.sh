#!/usr/bin/env bash
# Open a new window running an agent: pick dir → name
# Called from tmux bind C via display-popup
# Usage: agent-spawn.sh <pane_current_path>
source "$(dirname "$0")/lib.sh"

# Step 1 — Pick working directory
dir=$(pick_dir "$1") || exit 0

# Step 2 — Name prompt (prefilled default, editable via fzf print-query)
n=$(tmux list-windows -F "#{window_name}" | grep -c "^${AGENT_CMD}")
default="${AGENT_CMD}-$((n + 1))"
name=$(printf '' | fzf --reverse --print-query --header 'Window name' --query "$default" | head -1)
[ -n "$name" ] || exit 0

# Step 3 — Launch
tmux new-window -c "$dir" -n "$name" "$SHELL -c '${AGENT_CMD}; exec $SHELL'"
tmux set-option -w automatic-rename off
