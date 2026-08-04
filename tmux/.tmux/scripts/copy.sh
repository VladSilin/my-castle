#!/usr/bin/env bash
# Clipboard sink for copy-mode, called from the copy-mode-vi bindings in
# ~/.tmux.conf. Reads the selection on stdin, strips the TUI left-margin
# padding that Claude Code and friends add (textwrap.dedent preserves the
# relative indentation of code blocks), then hands it to whichever clipboard
# this machine actually has.
#
# Each branch pipes the stream straight through rather than capturing it in a
# variable, because command substitution would eat trailing newlines.

set -euo pipefail

dedent() {
  python3 -c 'import sys,textwrap;sys.stdout.write(textwrap.dedent(sys.stdin.read()))'
}

if [ "$(uname)" = "Darwin" ]; then
  # Local Mac: pbcopy writes the system clipboard directly. No terminal
  # involvement, so no OSC 52 clipboard-write permission prompt.
  dedent | pbcopy
elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  dedent | wl-copy
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
  dedent | xclip -selection clipboard
else
  # No local display — e.g. tmux on a headless box reached over SSH. OSC 52
  # pushes the text to the clipboard of whichever machine the *terminal* runs
  # on. Needs the terminal to permit clipboard writes
  # (ghostty: clipboard-write = allow).
  dedent | tmux load-buffer -w -
fi
