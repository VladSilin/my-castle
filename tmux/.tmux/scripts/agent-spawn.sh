#!/usr/bin/env bash
# Open a new window running an agent: pick agent → dir → name
# Called from tmux bind C via display-popup
# Usage: agent-spawn.sh <pane_current_path>
source "$(dirname "$0")/lib.sh"

# Step 1 — Pick which agent to spawn
agent=$(pick_command 'Pick agent:' "$(printf '%s\n' "${AGENTS[@]}")") || exit 0

# Step 2 — Pick working directory
dir=$(pick_dir "$1") || exit 0

# Step 3 — Name prompt (prefilled default, editable via fzf print-query)
n=$(tmux list-windows -F "#{window_name}" | grep -c "^${agent}")
default="${agent}-$((n + 1))"
name=$(printf '' | fzf --reverse --print-query --header 'Window name' --query "$default" | head -1)
[ -n "$name" ] || exit 0

# Step 4 — Create a normal interactive shell window, then type the agent
# command into it (same pattern as session-create.sh). Deliberately NOT
# `$SHELL -c '${agent}; exec $SHELL'` — that's a non-interactive shell, so
# zsh never sources .zshrc there: PATH additions (e.g. ~/.local/bin) are
# missing and the agent's tagging wrapper function is never defined either.
win=$(tmux new-window -P -F '#{window_id}' -c "$dir" -n "$name")
tmux set-option -w -t "$win" automatic-rename off
tmux send-keys -t "$win" "$agent" Enter
