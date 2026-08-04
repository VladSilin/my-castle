#!/usr/bin/env bash
# Open a grouped reference view of an existing session in a new terminal.
# The grouped session auto-kills on detach — nothing lingers in the session list.
# Usage: session-ref.sh [session-name]
source "$(dirname "$0")/lib.sh"

if [ -n "$1" ]; then
  target="$1"
else
  target=$(tmux list-sessions -F '#S' | grep -v '^ref-' \
    | fzf --reverse --header 'Pick session to reference') || exit 0
fi

[ -z "$target" ] && exit 1

ref_name="ref-$target"

# Clean up any stale ref session for this target
tmux has-session -t "$ref_name" 2>/dev/null && tmux kill-session -t "$ref_name"

tmux new-session -t "$target" -s "$ref_name" \; \
  set-hook -t "$ref_name" client-detached "kill-session"
