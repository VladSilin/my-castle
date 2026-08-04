#!/usr/bin/env bash
# Searchable hints popup — bound to prefix + ?
HINTS_FILE="$(dirname "$0")/../hints.txt"
fzf --reverse --header 'tmux hints (type to filter, esc to close)' < "$HINTS_FILE"
