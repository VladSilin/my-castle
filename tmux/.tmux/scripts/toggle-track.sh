#!/usr/bin/env bash
# Track fzf toggle selections in order
# Usage: toggle-track.sh <file> <item>
# If item is already in file, remove it (untoggle). Otherwise append it.
file="$1"
item="$2"
if grep -qxF "$item" "$file" 2>/dev/null; then
  grep -vxF "$item" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
else
  echo "$item" >> "$file"
fi
