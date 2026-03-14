#!/usr/bin/env bash
# Claude Code status line: shows model + context usage

set -euo pipefail

MONTHLY_CACHE="$HOME/.claude/monthly_cost_cache"
CACHE_MAX_AGE=300  # 5 minutes

get_monthly_cost() {
  local now cache_mtime age cached
  now="$(date +%s)"

  # Read cache if fresh enough
  if [[ -f "$MONTHLY_CACHE" ]]; then
    cache_mtime="$(stat -f %m "$MONTHLY_CACHE" 2>/dev/null || echo 0)"
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
    monthly="$(npx ccusage monthly --json 2>/dev/null | jq -r --arg m "$current_month" '.monthly[] | select(.month == $m) | .totalCost // 0')"
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

# Compute used tokens from percentage and total
total="${total//null/200000}"
pct_raw="${pct_raw//null/0}"
(( total = total > 0 ? total : 200000 ))
(( pct_raw = pct_raw > 0 ? pct_raw : 0 ))
(( used = total * pct_raw / 100 ))

# Percentage
pct=$pct_raw
(( pct = pct > 100 ? 100 : pct ))

# Color gradient: green → yellow → orange → red
if (( pct >= 90 )); then
  color='\033[31m'        # red
elif (( pct >= 71 )); then
  color='\033[38;5;208m'  # orange
elif (( pct >= 41 )); then
  color='\033[33m'        # yellow
else
  color='\033[32m'        # green
fi
reset='\033[0m'

# 10-char progress bar
filled=$(( pct / 10 ))
empty=$(( 10 - filled ))
bar=""
for (( i = 0; i < filled; i++ )); do bar+="█"; done
for (( i = 0; i < empty; i++ )); do bar+="░"; done

# Pretty model name
lc_model="$(echo "$model" | tr '[:upper:]' '[:lower:]')"
case "$lc_model" in
  *opus*)   display_model="Opus 4.6" ;;
  *sonnet*) display_model="Sonnet 4.6" ;;
  *haiku*)  display_model="Haiku 4.5" ;;
  *)        display_model="$model" ;;
esac

used_fmt="$(format_tokens "$used")"
total_fmt="$(format_tokens "$total")"

# Format session cost
cost="${cost//null/0}"
cost_fmt="$(printf '$%.2f' "$cost")"

# Monthly cost (cached, non-blocking)
monthly="$(get_monthly_cost)"
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
