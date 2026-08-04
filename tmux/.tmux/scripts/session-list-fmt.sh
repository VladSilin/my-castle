#!/usr/bin/env bash
# List sessions with [k] bracket prefixes for unique first-chars
tmux list-sessions -F '#S' | awk '
  { count[substr($0,1,1)]++; lines[NR]=$0; n=NR }
  END {
    for (i=1; i<=n; i++) {
      k = substr(lines[i],1,1)
      if (count[k]==1) printf "[%s] %s\n", k, lines[i]
      else print lines[i]
    }
  }
'
