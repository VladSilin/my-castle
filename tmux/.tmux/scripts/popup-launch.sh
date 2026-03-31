#!/bin/bash
# Popup launcher: pick dir → pick command → run in popup
# Usage: popup-launch.sh <pane_current_path>
source "$(dirname "$0")/lib.sh"

LOG=/tmp/popup-launch.log
echo "--- $(date) ---" >> "$LOG"

CURRENT_DIR="$PWD"
echo "CURRENT_DIR='$CURRENT_DIR'" >> "$LOG"

# Step 1 — Pick working directory
dir=$(pick_dir "$CURRENT_DIR")
rc=$?
echo "pick_dir rc=$rc dir='$dir'" >> "$LOG"
[ $rc -ne 0 ] && exit 0
cd "$dir" || exit 1

# Step 2 — Pick command
cmds=$(printf '%s\n' "${POPUP_CMDS[@]}")
echo "cmds='$cmds'" >> "$LOG"
cmd=$(pick_command "Pick command" "$cmds")
rc=$?
echo "pick_command rc=$rc cmd='$cmd'" >> "$LOG"
[ $rc -ne 0 ] && exit 0

# Step 3 — Launch
exec $cmd
