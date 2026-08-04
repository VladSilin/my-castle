#!/usr/bin/env bash
# Background watcher: notify when an agent pane finishes and is awaiting input
source "$(dirname "$0")/lib.sh"

# Ensure only one instance runs (lock via pidfile)
PIDFILE="/tmp/agent-notify.pid"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  exit 0
fi
echo $$ > "$PIDFILE"

state_file=$(mktemp)
trap "rm -f '$state_file' '$PIDFILE'" EXIT

# Announce that $1 is awaiting input. macOS routes through Notification Center
# and suppresses the alert when the terminal is already frontmost; elsewhere
# there may be no desktop at all (headless server over SSH), so fall back to
# notify-send and finally to a tmux status-line message, which always works.
notify_awaiting() {
  local pane="$1"
  if [ "$(uname)" = "Darwin" ]; then
    local frontapp
    frontapp=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')
    [ "$frontapp" = "$TERMINAL_APP" ] && return
    osascript -e "display notification \"$pane is waiting\" with title \"👾 Agent\" sound name \"Glass\""
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "👾 Agent" "$pane is waiting"
  else
    tmux display-message "👾 $pane is waiting"
  fi
}

# GNU sed takes the in-place suffix fused to the flag (-i.bak) and treats a
# separate '' as the script; BSD sed requires it separate. Pick per platform.
sed_inplace() {
  if [ "$(uname)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

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
      notify_awaiting "$pane"
    fi

    # Update state file
    if grep -q "^$pane " "$state_file" 2>/dev/null; then
      sed_inplace "s|^$pane .*|$pane $state|" "$state_file"
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
