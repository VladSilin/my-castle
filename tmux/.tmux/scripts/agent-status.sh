#!/bin/bash
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

BG="#4F4946"
OPEN=""
CLOSE=""
if [ "$awaiting" -gt 0 ]; then
  printf '#[bg=default,fg=%s]%s#[bg=%s,fg=#a782f7] 👾 %s #[fg=#ee9b40]⧑ %s #[bg=default,fg=%s]%s ' "$BG" "$OPEN" "$BG" "$total" "$awaiting" "$BG" "$CLOSE"
else
  printf '#[bg=default,fg=%s]%s#[bg=%s,fg=#a782f7] 👾 %s #[bg=default,fg=%s]%s ' "$BG" "$OPEN" "$BG" "$total" "$BG" "$CLOSE"
fi
