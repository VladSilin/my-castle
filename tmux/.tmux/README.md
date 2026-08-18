# tmux config

Custom tmux configuration with agent-aware navigation and status indicators.

## Dependencies

- **tmux** (tested with 3.x)
- **fzf** — fuzzy finder for session/window/pane navigation
- **bash** — scripts use bash-specific features (`source`, arrays)
- **jq** — used by agent status line hooks in `~/.claude/settings.json`

## Agent integration

Supports multiple agent CLIs at once (currently [Claude Code](https://claude.ai)
and [cursor-agent](https://cursor.com/docs/cli)), configured in `scripts/config.sh`:

```bash
AGENTS=("claude" "cursor-agent")

AGENT_COMM_CLAUDE="claude.exe"   # Claude's process name is unique — native match, no tag needed

SENTINEL="👾"        # character in an agent's status line
SENTINEL_TAIL=5      # lines from bottom to check
```

### Identification: native match, or mandatory tag

An agent pane is recognized one of two ways:

- **Native match** — the agent's OS process name (`pane_current_command`) is
  already unique, e.g. Claude's Electron binary (`claude.exe`). No tagging
  needed; ad-hoc launches (just typing `claude`, no popup, no wrapper) work
  the same as always.
- **Tag match** — for agents whose process name is ambiguous (node/python,
  shared by many other tools — cursor-agent shows up as plain `node`), the
  pane must be tagged with a `@agent` tmux user option. This is set by a
  `.zshrc` wrapper function (see `shell/.zshrc`'s `cursor-agent()`) on
  launch and cleared on exit. There's deliberately no attempt to guess an
  ambiguous pane's agent from process name or argv — if it's not tagged, it's
  not recognized.

`scripts/lib.sh`'s `is_agent_pane` implements this check; `list_agent_panes`
and `count_agent_panes` use it.

A pane running an ambiguous agent without its tag (new shell, bash instead
of zsh, dotfiles not sourced, launched some other way that skips the
wrapper) is simply not recognized as an agent pane — no `⧑` icon, doesn't
count toward `C-a >` jump targets — until it's tagged, either by
relaunching through the wrapper or manually:
`tmux set-option -p @agent cursor-agent`.

An earlier version of this tried to warn about exactly this case by
comparing `pgrep -f <pattern>` process counts against tagged-pane counts.
Dropped: cursor-agent runs its own persistent background helper processes
(e.g. a `worker-server`) under the same install path, which match any
reasonable pattern and permanently inflate the count regardless of tagging
— a wrong, always-on warning is worse than no warning.

### Awaiting detection

An agent's status line (configured in `~/.claude/statusline.sh` for Claude,
`~/.cursor/statusline.sh` for cursor-agent) embeds a sentinel character (👾).
When the agent shows a permission prompt, plan confirmation, or other
blocking dialog, the status line is hidden. Detection checks the last few
non-empty lines of the pane for the sentinel's **absence**.

This replaces the previous approach of pattern-matching specific prompt strings, and catches all awaiting states without maintenance. The sentinel is shared across agents — `is_awaiting` doesn't need to know which agent it's checking, only that *an* agent pane's status line is expected there.

### Status line setup

Each agent must have a status line that includes the sentinel. For Claude Code, this is configured in `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
```

cursor-agent's equivalent lives in `~/.cursor/cli-config.json`:

```json
"statusLine": { "type": "command", "command": "/Users/vsilin/.cursor/statusline.sh" }
```

### Adding a new agent

The identification/tagging pieces above scale to a new agent as config-only
additions: a name in `AGENTS`, and (if its process name is ambiguous) a
wrapper function in `.zshrc` that tags it — nothing else required.

**Awaiting detection does not carry over automatically.** It only works
because Claude and cursor-agent both happen to hide a scriptable status
line while blocked. Before wiring in a new agent, confirm it has the same
property. If it doesn't, the agent still gets identified/tagged/counted,
but is presence-only — no `⧑` icon, never shows as awaiting, never a
`C-a >` target — until a per-agent detection strategy is added for it.

## Key bindings

| Binding | Action | Script |
|---------|--------|--------|
| `C-a s` | Fuzzy session switcher (ctrl-x=kill, single-char acceleration) | `scripts/session-switch.sh` |
| `C-a w` | Fuzzy cross-session window switcher | inline |
| `C-a S` | Quick bare session (name prompt, dir=$HOME) | inline |
| `C-a N` | New session with pre-configured windows (dir → name → commands) | `scripts/session-create.sh` |
| `C-a C` | Spawn new agent window (pick agent → dir → name) | `scripts/agent-spawn.sh` |
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
| `config.sh` | Shared constants (agent table, sentinel, colors, icons, polling intervals) |
| `lib.sh` | Shared functions: `is_awaiting`, `is_agent_pane`, `list_agent_panes`, `count_agent_panes`, `pick_command` |
| `agent-status.sh` | Tmux status bar pill showing agent count and awaiting count |
| `agent-jump.sh` | Cycles through awaiting agent panes |
| `agent-spawn.sh` | Opens a new named agent window (pick agent → dir → name) |
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
