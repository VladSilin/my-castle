# Shared config for tmux scripts

# Agent
AGENT_CMD="claude"        # command to invoke
# Process name tmux reports for a running agent pane. macOS ships the Electron
# binary (claude.exe); the Linux build reports plain "claude". Every agent
# feature (status bar, prefix+>, prefix+m) matches on this string, so a wrong
# value silently means "no agent panes exist".
if [ "$(uname)" = "Darwin" ]; then
  AGENT_PROC="claude.exe"
else
  AGENT_PROC="claude"
fi
SENTINEL="👾"
SENTINEL_TAIL=5

# Tools
EDITOR_CMD="nvim"
SHELL_CMD="zsh"

# Colors (script-facing; full palette stays in .tmux.conf)
COLOR_YELLOW="#ee9b40"
COLOR_BLUE="#a782f7"
COLOR_LIGHT_GRAY="#4F4946"

# Icons
AWAITING_ICON="⧑"
AWAITING_ICON_ANSI=$'\033[38;5;172m⧑\033[0m'

# Project search
PROJECT_DIR="$HOME"
PROJECT_DEPTH=5

# Popup launcher commands (C-a Space)
POPUP_CMDS=("$AGENT_CMD" "$EDITOR_CMD" "$SHELL_CMD")

# Polling intervals (seconds)
STATUS_INTERVAL=1      # how often tmux re-evaluates status bar (agent-status.sh)
NOTIFY_INTERVAL=1      # how often agent-notify.sh checks for busy → awaiting transitions

# Notification
TERMINAL_APP="ghostty"
