# tmux config

Custom tmux configuration with agent-aware navigation and status indicators.

## Dependencies

- **tmux** (tested with 3.x)
- **fzf** — fuzzy finder for session/window/pane navigation
- **bash** — scripts use bash-specific features (`source`, arrays)
- **jq** — used by agent status line hooks in `~/.claude/settings.json`

## Agent integration

Designed for [Claude Code](https://claude.ai) but agent-agnostic via `scripts/config.sh`:

```bash
AGENT_CMD="claude"   # process name to match
SENTINEL="👾"        # character in the agent's status line
SENTINEL_TAIL=5      # lines from bottom to check
```

### Awaiting detection

The agent's status line (configured in `~/.claude/statusline.sh`) embeds a sentinel character (👾). When the agent shows a permission prompt, plan confirmation, or other blocking dialog, the status line is hidden. Detection checks the last few non-empty lines of the pane for the sentinel's **absence**.

This replaces the previous approach of pattern-matching specific prompt strings, and catches all awaiting states without maintenance.

### Status line setup

The agent must have a status line that includes the sentinel. For Claude Code, this is configured in `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
```

## Key bindings

| Binding | Action | Script |
|---------|--------|--------|
| `C-a s` | Fuzzy session switcher (ctrl-x=kill, single-char acceleration) | `scripts/session-switch.sh` |
| `C-a w` | Fuzzy cross-session window switcher | inline |
| `C-a S` | Quick bare session (name prompt, dir=$HOME) | inline |
| `C-a N` | New session with pre-configured windows (dir → name → commands) | `scripts/session-create.sh` |
| `C-a C` | Spawn new agent window (dir → name) | `scripts/agent-spawn.sh` |
| `C-a m` | Two-step pane finder (pick command → pick pane) | `scripts/pane-picker.sh` |
| `C-a g` | Session-scoped pane jump | `scripts/session-jump.sh` |
| `C-a >` | Jump to next agent pane awaiting input | `scripts/agent-jump.sh` |
| `C-a ?` | Searchable hints popup | `scripts/hints.sh` |
| `C-a Space` | Quick Claude popup (pick dir) | inline |
| `C-a R` | Restart agent notification watcher | inline |

## Scripts

All scripts live in `scripts/` and share config via `config.sh` and functions via `lib.sh`.

| File | Purpose |
|------|---------|
| `config.sh` | Shared constants (agent command, sentinel, colors, icons, polling intervals) |
| `lib.sh` | Shared functions: `is_awaiting`, `list_agent_panes`, `count_agent_panes`, `pick_command` |
| `agent-status.sh` | Tmux status bar pill showing agent count and awaiting count |
| `agent-jump.sh` | Cycles through awaiting agent panes |
| `agent-spawn.sh` | Opens a new named agent window |
| `agent-notify.sh` | Background watcher — sends desktop notification on busy→awaiting transition |
| `pane-picker.sh` | Fuzzy pane finder with ⧑ awaiting indicator |
| `session-jump.sh` | Session-scoped fuzzy command/pane jump |
| `session-switch.sh` | Session switcher with single-char acceleration and ctrl-x to kill |
| `session-create.sh` | Create session: bare (name only) or full (dir → name → multi-select commands) |
| `session-list-fmt.sh` | Format session list with `[k]` unique-char prefixes for acceleration |
| `hints.sh` | Display searchable hints popup via fzf |
| `toggle-track.sh` | Toggle items in a tracking file (used by fzf multi-select) |

## iTerm2 notes

Enable **Use built-in Powerline glyphs** in iTerm2 profile settings for pixel-perfect rendering of the status bar pill edges (nerdfont half-round glyphs E0B6/E0B4).
