#!/usr/bin/env bash
# Shared functions for tmux agent scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Pick a working directory via fzf
# Usage: pick_dir [current_dir]
# Returns selected path on stdout, exits 1 on cancel
# Offers "· current dir" sentinel when current_dir is provided
#
# Source order: zoxide frecent dirs (instant, ranked) → fd walk of $PROJECT_DIR.
# awk dedupes by first-seen so frecent hits stay on top; fzf --tiebreak=index
# preserves that ordering when match scores tie.
pick_dir() {
  local current="$1"
  local dir

  dir=$({
    [ -n "$current" ] && echo '· current dir'
    zoxide query -l 2>/dev/null
    fd --type d --hidden --max-depth "$PROJECT_DEPTH" \
       --exclude .git --exclude node_modules --exclude Library \
       --exclude .Trash --exclude .cache --exclude .venv --exclude .npm \
       . "$PROJECT_DIR" 2>/dev/null
  } | awk '!seen[$0]++' \
    | fzf --reverse --tiebreak=index --header 'Pick working directory') || return 1

  [ -n "$dir" ] || return 1

  if [ "$dir" = "· current dir" ]; then
    echo "$current"
  else
    echo "$dir"
  fi
}

# Check if a pane is awaiting input (sentinel absent from bottom of pane)
# Usage: is_awaiting <pane_id>
is_awaiting() {
  local pane="$1"
  ! tmux capture-pane -t "$pane" -p 2>/dev/null | grep -v '^$' | tail -"$SENTINEL_TAIL" | grep -q "$SENTINEL"
}

# List all agent panes as "session:win.pane" (one per line)
list_agent_panes() {
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' 2>/dev/null \
    | grep " ${AGENT_PROC}$" | cut -d' ' -f1
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
  local result key sel cmd

  # Single awk pass: compute duplicated first-chars, build hint list and bind/unbind args
  eval "$(echo "$cmds" | awk '
    NR==FNR { count[substr($0,1,1)]++; next }
    {
      k = substr($0,1,1)
      if (count[k] == 1) {
        keys = keys (keys ? "," : "") k
        binds = binds " --bind " shquote(k ":become(echo " k ")")
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
  ' <(echo "$cmds") <(echo "$cmds"))"

  local unbind_arg=""
  [ -n "$hotkeys" ] && unbind_arg="--bind 'change:unbind($hotkeys)'"

  local global_bind=""
  [ "${enable_global:-0}" = "1" ] && global_bind="--bind 'alt-enter:become(echo GLOBAL:{})'"

  cmd=$(eval "printf '%s\n' \"\${hint[@]}\" | fzf --reverse --header \"\$header\" $hotbinds $global_bind $unbind_arg") || return 1

  # Single char output means a hotkey fired; map back to full item
  if [ ${#cmd} -eq 1 ]; then
    cmd=$(echo "$cmds" | grep "^$cmd")
  else
    cmd=$(echo "$cmd" | sed 's/^\[.\] //')
  fi
  [ -n "$cmd" ] || return 1
  echo "$cmd"
}
