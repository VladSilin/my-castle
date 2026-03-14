#!/bin/bash
# Shared functions for tmux agent scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/agent.conf"

# Check if a pane is awaiting input (sentinel absent from bottom of pane)
# Usage: is_awaiting <pane_id>
is_awaiting() {
  local pane="$1"
  ! tmux capture-pane -t "$pane" -p 2>/dev/null | grep -v '^$' | tail -"$SENTINEL_TAIL" | grep -q "$SENTINEL"
}

# List all agent panes as "session:win.pane" (one per line)
list_agent_panes() {
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' 2>/dev/null \
    | grep " ${AGENT_CMD}$" | cut -d' ' -f1
}

# Count agent panes
count_agent_panes() {
  local panes
  panes=$(list_agent_panes)
  [ -z "$panes" ] && echo 0 && return
  echo "$panes" | wc -l | tr -d ' '
}

# Build fzf command picker from a list of commands
# Usage: pick_command <header> <commands>
# Returns selected command on stdout, exits 1 on cancel
pick_command() {
  local header="$1"
  local cmds="$2"
  local keys expect hint result key sel cmd

  keys=$(echo "$cmds" | cut -c1 | sort | uniq -d)

  expect=$(echo "$cmds" | while read c; do
    k=$(echo "$c" | cut -c1)
    echo "$keys" | grep -qx "$k" || printf '%s,' "$k"
  done | sed 's/,$//')

  hint=$(echo "$cmds" | while read c; do
    k=$(echo "$c" | cut -c1)
    if echo "$keys" | grep -qx "$k"; then echo "$c"
    else echo "[$k] $c"; fi
  done)

  result=$(echo "$hint" | fzf --reverse --header "$header" --expect="$expect") || return 1
  key=$(echo "$result" | head -1)
  sel=$(echo "$result" | tail -1 | sed 's/^\[.\] //')

  if [ -n "$key" ]; then
    cmd=$(echo "$cmds" | grep "^$key")
  else
    cmd="$sel"
  fi
  [ -n "$cmd" ] || return 1
  echo "$cmd"
}
