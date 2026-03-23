# Shared config for tmux scripts

# Agent
AGENT_CMD="claude"
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

# Project search
PROJECT_DIR="$HOME"
PROJECT_DEPTH=5

# Polling intervals (seconds)
STATUS_INTERVAL=1      # how often tmux re-evaluates status bar (agent-status.sh)
NOTIFY_INTERVAL=1      # how often agent-notify.sh checks for busy → awaiting transitions

# Notification
TERMINAL_APP="ghostty"
