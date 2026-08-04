#!/usr/bin/env bash
# Claude Code status line: shows model + context usage

set -euo pipefail

MONTHLY_CACHE="$HOME/.claude/monthly_cost_cache"
CACHE_MAX_AGE=300  # 5 minutes

get_monthly_cost() {
  local now cache_mtime age cached
  now="$(date +%s)"

  # Read cache if fresh enough.
  # GNU stat spells mtime `-c %Y`, BSD spells it `-f %m`. Try GNU first: BSD
  # rejects -c with a usage error and no stdout, so the fallback is clean. The
  # reverse order is NOT safe -- GNU reads `-f %m` as --file-system on a file
  # named %m, printing a whole "File: ... Blocks: ..." block to STDOUT before
  # exiting 1, which the fallback then appends its answer to. That garbage
  # reaching $(( )) is a syntax error, and under `set -u` it aborts the script,
  # so the status line silently disappears.
  # The numeric guard makes this independent of which stat emits what.
  if [[ -f "$MONTHLY_CACHE" ]]; then
    cache_mtime="$(stat -c %Y "$MONTHLY_CACHE" 2>/dev/null || stat -f %m "$MONTHLY_CACHE" 2>/dev/null || true)"
    [[ "$cache_mtime" =~ ^[0-9]+$ ]] || cache_mtime=0
    age=$(( now - cache_mtime ))
    if (( age < CACHE_MAX_AGE )); then
      cat "$MONTHLY_CACHE"
      return
    fi
  fi

  # Refresh cache in background so we don't block the status line
  # Return stale value (or fallback) immediately
  (
    current_month="$(date +%Y-%m)"
    monthly="$(npx ccusage monthly --json 2>/dev/null | jq -r --arg m "$current_month" '.monthly[] | select(.period == $m or .month == $m) | .totalCost // 0')"
    printf '%.2f' "${monthly:-0}" > "$MONTHLY_CACHE"
  ) &

  # Return stale cache or 0 on first run
  if [[ -f "$MONTHLY_CACHE" ]]; then
    cat "$MONTHLY_CACHE"
  else
    echo "0.00"
  fi
}

format_tokens() {
  local n="$1"
  if (( n >= 1000000 )); then
    printf "%.1fM" "$(echo "scale=1; $n / 1000000" | bc)"
  elif (( n >= 1000 )); then
    printf "%dK" "$(( n / 1000 ))"
  else
    printf "%d" "$n"
  fi
}

# Read JSON from stdin
input="$(cat)"

# Try to parse with jq; bail on invalid JSON
if ! echo "$input" | jq empty 2>/dev/null; then
  echo "-- / --"
  exit 0
fi

model="$(echo "$input" | jq -r '.model.display_name // .model // "unknown"')"
total="$(echo "$input" | jq -r '.context_window.context_window_size // 200000')"
pct_raw="$(echo "$input" | jq -r '.context_window.used_percentage // 0')"
cost="$(echo "$input" | jq -r '.cost.total_cost_usd // 0')"

# Coerce to a plain integer. Claude Code can report used_percentage
# fractionally (12.7), and bash arithmetic has no floats -- it treats the '.'
# as a syntax error and aborts. Anything unparseable becomes 0.
to_int() {
  local v="${1:-0}"
  v="${v%%.*}"
  [[ "$v" =~ ^-?[0-9]+$ ]] || v=0
  printf '%s' "$v"
}

# Same idea for values headed to printf '%.2f', which keeps the fractional
# part. printf exits non-zero on a non-number ("invalid number"), and that
# blanks the entire status line. Two ways that happens in practice: an empty
# stdin payload, which `jq empty` accepts so the invalid-JSON guard misses it,
# and a monthly cache file that a failed ccusage run left garbage in.
to_num() {
  local v="${1:-0}"
  [[ "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || v=0
  printf '%s' "$v"
}

# Compute used tokens from percentage and total
total="$(to_int "${total//null/200000}")"
pct_raw="$(to_int "${pct_raw//null/0}")"

# Every clamp below is written as `(( test )) || assign` rather than a bare
# `(( x = ... ))`. A bare arithmetic statement whose result is 0 returns exit
# status 1, and under `set -e` that kills the script with no output at all --
# which is what happened at 0% context, i.e. the start of every session.
(( total > 0 )) || total=200000
(( pct_raw > 0 )) || pct_raw=0
used=$(( total * pct_raw / 100 ))

# Percentage
pct=$pct_raw
(( pct <= 100 )) || pct=100

# Color gradient: green → yellow → orange → red
#
# All four are explicit 256-color indices rather than the basic ANSI codes
# (31/32/33). Those basic codes are not colors, they are palette slots each
# terminal theme defines for itself -- ShellFish and Monokai-family themes
# render "green" as a chartreuse that reads as yellow, so a 0% status line
# looked like a warning. Only orange was pinned before, which is why it was
# the one that always looked right.
if (( pct >= 90 )); then
  color='\033[38;5;196m'  # red
elif (( pct >= 71 )); then
  color='\033[38;5;208m'  # orange
elif (( pct >= 41 )); then
  color='\033[38;5;220m'  # yellow
else
  color='\033[38;5;40m'   # green
fi
reset='\033[0m'

# 10-char progress bar
filled=$(( pct / 10 ))
empty=$(( 10 - filled ))
bar=""
for (( i = 0; i < filled; i++ )); do bar+="█"; done
for (( i = 0; i < empty; i++ )); do bar+="░"; done

# Model name (display_name from Claude Code is already clean, e.g. "Opus 4.8 (1M context)")
display_model="$model"

used_fmt="$(format_tokens "$used")"
total_fmt="$(format_tokens "$total")"

# Format session cost
cost="$(to_num "${cost//null/0}")"
cost_fmt="$(printf '$%.2f' "$cost")"

# Monthly cost (cached, non-blocking)
monthly="$(to_num "$(get_monthly_cost)")"
monthly_fmt="$(printf '$%.2f' "$monthly")"

dim='\033[2m'
cyan='\033[36m'

# Hook debug: show last N events as a chain
# Toggle with: touch /tmp/claude-hook-debug (on) / rm /tmp/claude-hook-debug (off)
hook_info=""
session_id="$(echo "$input" | jq -r '.session_id // ""')"
hook_log="/tmp/claude-hooks/${session_id}.log"
if [[ -f "$HOME/.claude/hook-debug-flag" && -n "$session_id" && -f "$hook_log" ]]; then
  events=()
  while read -r ts evt; do
    events+=("$evt")
  done < <(tail -3 "$hook_log")
  if (( ${#events[@]} > 0 )); then
    last_idx=$(( ${#events[@]} - 1 ))
    chain=""
    for (( i = last_idx; i >= 0; i-- )); do
      offset=$(( last_idx - i ))
      if (( offset == 0 )); then
        label="[t]"
        entry="\033[1;36m${label} ${events[$i]}${reset}"
      else
        label="[t-${offset}]"
        entry="${dim}${label} ${events[$i]}${reset}"
      fi
      if [[ -n "$chain" ]]; then
        chain="${chain}  ${entry}"
      else
        chain="${entry}"
      fi
    done
    hook_info="\n${cyan}◆◆ ${chain}"
  fi
fi

# 👾 sentinel marker for tmux capture-pane detection of awaiting state.
# If 👾 is absent from a Claude pane's output, the pane is in an awaiting state
# (permission prompt, plan confirmation, etc.) where the status line is not rendered.
# Detection logic: ~/.tmux/claude-status.sh, bind > and bind m in ~/.tmux.conf
printf '%b' "👾 ${display_model} · ${color}${pct}% [${bar}]${reset} ${used_fmt} / ${total_fmt} · ${cost_fmt} ${dim}(${monthly_fmt}/mo)${reset}${hook_info}\n"
