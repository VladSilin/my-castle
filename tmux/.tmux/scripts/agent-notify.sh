#!/bin/bash
# Background watcher: notify when an agent pane finishes and is awaiting input
source "$(dirname "$0")/lib.sh"
state_file=$(mktemp)
trap "rm -f '$state_file'" EXIT

while true; do
  panes=$(list_agent_panes)
  [ -z "$panes" ] && sleep "$NOTIFY_INTERVAL" && continue

  while IFS= read -r pane; do
    [ -z "$pane" ] && continue

    if is_awaiting "$pane"; then
      state="awaiting"
    else
      state="busy"
    fi

    prev=$(grep "^$pane " "$state_file" 2>/dev/null | cut -d' ' -f2)

    # Notify on transition from busy → awaiting (skip if terminal is focused)
    if [ "$prev" = "busy" ] && [ "$state" = "awaiting" ]; then
      frontapp=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')
      if [ "$frontapp" != "$TERMINAL_APP" ]; then
        osascript -e "display notification \"$pane is waiting\" with title \"👾 Agent\" sound name \"Glass\""
      fi
    fi

    # Update state file
    if grep -q "^$pane " "$state_file" 2>/dev/null; then
      sed -i '' "s|^$pane .*|$pane $state|" "$state_file"
    else
      echo "$pane $state" >> "$state_file"
    fi
  done <<< "$panes"

  # Remove stale panes from state file
  tmp=$(mktemp)
  while IFS= read -r line; do
    p=$(echo "$line" | cut -d' ' -f1)
    echo "$panes" | grep -qx "$p" && echo "$line"
  done < "$state_file" > "$tmp"
  mv "$tmp" "$state_file"

  sleep "$NOTIFY_INTERVAL"
done
