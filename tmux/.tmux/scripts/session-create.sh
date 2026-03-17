#!/bin/bash
# Create a new session with pre-configured windows
# Usage: session-create.sh <pane_current_path>
source "$(dirname "$0")/lib.sh"

FALLBACK_DIR="${1:-$HOME}"

# Config
BASE_DIR="$PROJECT_DIR"
EXCLUDE="$SHELL_CMD|bash"
INCLUDE=("$AGENT_CMD" "shell" "$EDITOR_CMD")

# Step 1 — Pick working directory
DIR=$(find "$BASE_DIR" -maxdepth "$PROJECT_DEPTH" -type d 2>/dev/null \
  | fzf --reverse --header "Pick working directory") || exit 0

[ -n "$DIR" ] || exit 0

# Step 2 — Name prompt
taken=$(tmux list-sessions -F '#S' | cut -c1 | sort -u | sed 's/./[&]/g' | tr -d '\n')
name=$(printf '' | fzf --reverse --print-query --header "Taken: $taken" | head -1)
[ -n "$name" ] || exit 0

# Step 3 — Gather commands from running panes
commands=$(tmux list-panes -a -F '#{pane_current_command}' | sort -u | grep -vE "^($EXCLUDE)$")
# Ensure inclusion list items are present
for cmd in "${INCLUDE[@]}"; do
  echo "$commands" | grep -qx "$cmd" || commands=$(printf '%s\n%s' "$cmd" "$commands")
done

# Build defaults label from INCLUDE list (minus "shell")
defaults_label=$(printf '%s' "${INCLUDE[*]}" | sed 's/ /, /g')
sentinel="► defaults ($defaults_label)"

# Step 4 — Multi-select picker with hotkey acceleration
# Adapted from pick_command() in lib.sh but using toggle instead of become
# Uses a temp file to preserve toggle order (fzf --multi outputs in display order)
toggle_file=$(mktemp)
trap "rm -f '$toggle_file'" EXIT

eval "$(echo "$commands" | awk '
  NR==FNR { count[substr($0,1,1)]++; next }
  {
    n++  # 1-based index within commands; +1 for sentinel = fzf pos
    pos = n + 1
    k = substr($0,1,1)
    if (count[k] == 1) {
      keys = keys (keys ? "," : "") k
      binds = binds " --bind " shquote(k ":pos(" pos ")+toggle+execute(~/.tmux/scripts/toggle-track.sh " shquote(tf) " " shquote($0) ")")
      print "hint+=(" shquote("[" k "] " $0) ")"
    } else {
      print "hint+=(" shquote($0) ")"
    }
  }
  function shquote(s) { gsub(/\047/, "\047\\\047\047", s); return "\047" s "\047" }
  END {
    print "hotkeys=" shquote(keys)
    print "hotbinds=" shquote(binds)
  }
' tf="$toggle_file" <(echo "$commands") <(echo "$commands"))"

local_unbind=""
[ -n "$hotkeys" ] && local_unbind="--bind 'change:unbind($hotkeys)'"

# Prepend sentinel to hint list
hint=("$sentinel" "${hint[@]}")

# tab also tracks toggle order
tab_bind="--bind 'tab:toggle+execute(~/.tmux/scripts/toggle-track.sh \"$toggle_file\" {})'"

eval "printf '%s\n' \"\${hint[@]}\" | fzf --reverse --multi --header 'tab/hotkey=toggle  enter=confirm' $hotbinds $tab_bind $local_unbind" || exit 0

# If toggle file is empty (just pressed enter on defaults), use INCLUDE list
if [ ! -s "$toggle_file" ]; then
  selected_cmds=("${INCLUDE[@]}")
else
  # Read toggle-order selections, strip [k] prefixes
  selected_cmds=()
  while IFS= read -r line; do
    cmd=$(echo "$line" | sed 's/^\[.\] //')
    # Skip sentinel
    [[ "$cmd" == "► defaults"* ]] && { selected_cmds=("${INCLUDE[@]}"); break; }
    selected_cmds+=("$cmd")
  done < "$toggle_file"
fi

[ ${#selected_cmds[@]} -eq 0 ] && exit 0

# Step 5 — Create session with first command, then add remaining windows
base=$(tmux show -gv base-index)
tmux new-session -d -c "$DIR" -s "$name"
[ "${selected_cmds[0]}" != "shell" ] && tmux send-keys -t "$name:$base" "${selected_cmds[0]}" Enter

for ((i = 1; i < ${#selected_cmds[@]}; i++)); do
  tmux new-window -t "$name" -c "$DIR"
  [ "${selected_cmds[$i]}" != "shell" ] && tmux send-keys -t "$name:$((base + i))" "${selected_cmds[$i]}" Enter
done

# Attach or switch depending on whether we're inside tmux
if [ -n "$TMUX" ]; then
  tmux switch-client -t "$name"
else
  tmux attach-session -t "$name"
fi
