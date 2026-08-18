# Shared config for tmux scripts

# Agents recognized by the tmux integration.
AGENTS=("claude" "cursor-agent")

# Claude's process name is unique — native match, no @agent tag required.
# macOS reports the Electron binary as claude.exe; Linux reports claude.
# Ad-hoc `claude` launches (no wrapper, no popup) therefore keep working.
if [ "$(uname)" = "Darwin" ]; then
  AGENT_COMM_CLAUDE="claude.exe"
else
  AGENT_COMM_CLAUDE="claude"
fi

# Agents whose process name is ambiguous (node/python, shared by many other
# tools) are identified only via the @agent tag set by their .zshrc wrapper
# function — never guessed at from process name. If untagged, the pane is
# simply not recognized as an agent pane (see tmux/.tmux/README.md
# "Adding a new agent").

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
POPUP_CMDS=("${AGENTS[@]}" "$EDITOR_CMD" "$SHELL_CMD")

# Polling intervals (seconds)
STATUS_INTERVAL=1      # how often tmux re-evaluates status bar (agent-status.sh)
NOTIFY_INTERVAL=1      # how often agent-notify.sh checks for busy → awaiting transitions

# Notification
TERMINAL_APP="ghostty"
