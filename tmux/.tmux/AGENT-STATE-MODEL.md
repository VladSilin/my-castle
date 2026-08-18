# Agent state model (design sketch)

Design for generalizing agent-awareness beyond Claude Code — to cursor-agent
and other CLI agents — without adopting a separate multiplexer (e.g. herdr).
Not yet implemented.

## Problem

Current setup (`config.sh`/`lib.sh`) hardcodes a single agent:
- Identification via `AGENT_PROC` process-name matching — breaks for
  node-based CLIs like cursor-agent, which tmux just sees as `node` (not
  unique enough to distinguish from any other node process).
- Awaiting-input detection via a sentinel character in Claude's scriptable
  statusline, checked for absence — this mechanism doesn't exist for agents
  without an equivalent scriptable statusline/hook.

## Core idea

Separate *detection* (many strategies, different cadences) from
*consumption* (status bar, jump, notify) via a shared state store. Every
consumer only ever needs to read pane state — it shouldn't matter which
strategy produced it.

## Identification

Tag panes/windows at launch time regardless of how the agent was started
(popup spawner or typed directly), via a shell wrapper function per agent:

```bash
claude() {
  [ -n "$TMUX" ] && tmux set-option -w @agent claude
  command claude "$@"
  [ -n "$TMUX" ] && tmux set-option -wu @agent
}
```

Generated from a config table, one per agent command. Detection scripts key
off the `@agent` user option instead of process-name matching. Stale tags
from a hard-killed pane self-heal next time the window is reused.

## State enum

Keep it small and let precision vary by detector — don't force every
detector to populate the same fine-grained enum:

- Required (all detectors must produce): `busy | awaiting | unknown`
- Optional detail string, populated only by detectors precise enough to
  know more: `awaiting:permission`, `awaiting:plan-review`,
  `awaiting:input`. Coarser detectors leave this null.

## Detector contract

One shape covers both push (event-driven) and pull (polled) sources:

```
detector(pane_id, remembered_state) -> (new_state, remembered_state')
```

- **Push (Claude hooks):** `remembered_state` is trivial/unused — a hook
  event *is* the new state. Turn-start (`PreToolUse`) → write `busy`.
  Claude Code's `Notification` hook (fires when it needs attention) and
  `Stop` hook (fires when a turn ends) → write `awaiting`. No interval, no
  re-sampling. **Should replace the sentinel-in-statusline scrape entirely
  for Claude** — verify exact hook event names/payloads against current
  docs before wiring this up.
- **Pull (sentinel-presence, idle-hash):** these need `remembered_state`.
  Sentinel-presence needs only the current sample; idle-hash needs the
  previous hash + timestamp to decide "unchanged for N seconds." Both run
  inside the existing 1s poll loop in `agent-notify.sh`.

## Fallback chaining per agent type

Configured once in `config.sh`:

```
AGENTS=(
  claude:hook              # trust pushed @agent_state directly; poller is a no-op for these panes
  cursor:sentinel,idle     # try sentinel scrape first (pending verification /statusline hides the same way); fall back to idle-hash
  *:idle                   # anything untagged
)
```

Poller logic per pane: if a push write landed within the last ~2 poll
intervals, trust it and skip pulling entirely (push is fresher and
authoritative); otherwise run the configured pull chain in order.

## Where the map lives

tmux pane/window user options (`@agent`, `@agent_state`, `@agent_state_ts`),
not a separate file:

- Shares one store with the identification tag above.
- No file-locking concern between a hook-writer and the poller racing on
  the same pane — tmux serializes `set-option` calls itself.
- Directly usable in `status-left`/`status-right` format strings
  (`#{@agent_state}`) with no extra shelling out.

## Known limitations

- Idle-hash can't distinguish "waiting for you" from "crashed" or "silently
  computing with no terminal output" (e.g. mid-compaction, long tool call).
- cursor-agent hooks are currently IDE-only, not CLI — so push detection
  isn't available for it yet even if the CLI's `/statusline` turns out to
  be scriptable/compatible with the sentinel trick.

## Lighter-than-herdr alternatives considered

- [tmux-agent-sidebar](https://terminaltrove.com/herdr/) — plugin that
  renders agent state from hook events in a tmux sidebar; closest in spirit
  to this design.
- [Claude Squad](https://github.com/smtg-ai/claude-squad) — Go TUI using
  tmux + git worktrees as primitives rather than replacing tmux; narrower
  than herdr but still its own dashboard/navigation paradigm layered on top.
- Floating notifier widgets (CodeIsland, Vibe Island, AgentBell) —
  menu-bar apps aggregating "needs attention" state from hook events, no
  multiplexer opinion at all; only as good as each agent's hook support.

Decision: build this ourselves rather than adopt any of the above — both
"hard" problems (identification, awaiting-detection) reduce to extending
scripts already in place, not a rewrite, and adopting a third-party tool
means giving up the fzf-driven navigation already built for a feature
(unified agent state) mostly reachable on our own.
