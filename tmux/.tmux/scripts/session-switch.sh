#!/bin/bash
# Session switcher with single-char acceleration and ctrl-x to kill
# Called from tmux bind s via display-popup
source "$(dirname "$0")/lib.sh"

sessions=$(tmux list-sessions -F '#S')

eval "$(echo "$sessions" | awk '
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
' <(echo "$sessions") <(echo "$sessions"))"

unbind_arg=""
[ -n "$hotkeys" ] && unbind_arg="--bind 'change:unbind($hotkeys)'"

result=$(eval "printf '%s\n' \"\${hint[@]}\" | fzf --reverse \
  --header 'enter=switch, ctrl-x=kill' \
  $hotbinds $unbind_arg \
  --bind 'ctrl-x:execute-silent(tmux kill-session -t {2})+reload(~/.tmux/scripts/session-list-fmt.sh)'") || exit 0

if [ ${#result} -eq 1 ]; then
  sess=$(echo "$sessions" | grep "^$result")
else
  sess=$(echo "$result" | sed 's/^\[.\] //')
fi
[ -n "$sess" ] && tmux switch-client -t "$sess"
