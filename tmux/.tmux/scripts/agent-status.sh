#!/usr/bin/env bash
# Tmux status bar pill: shows agent count and how many are awaiting input
# Outputs tmux-formatted pill, or nothing if no agent panes
source "$(dirname "$0")/lib.sh"

panes=$(list_agent_panes)
total=$(count_agent_panes)
[ "$total" -eq 0 ] && exit 0

awaiting=0
for p in $panes; do
  is_awaiting "$p" && awaiting=$((awaiting + 1))
done

BG="$COLOR_LIGHT_GRAY"
OPEN=""
CLOSE=""
if [ "$awaiting" -gt 0 ]; then
  printf '#[bg=default,fg=%s]%s#[bg=%s,fg=%s] %s %s #[fg=%s]%s %s #[bg=default,fg=%s]%s ' "$BG" "$OPEN" "$BG" "$COLOR_BLUE" "$SENTINEL" "$total" "$COLOR_YELLOW" "$AWAITING_ICON" "$awaiting" "$BG" "$CLOSE"
else
  printf '#[bg=default,fg=%s]%s#[bg=%s,fg=%s] %s %s #[bg=default,fg=%s]%s ' "$BG" "$OPEN" "$BG" "$COLOR_BLUE" "$SENTINEL" "$total" "$BG" "$CLOSE"
fi
