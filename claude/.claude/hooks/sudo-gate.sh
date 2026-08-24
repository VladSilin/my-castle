#!/usr/bin/env bash
# PreToolUse(Bash) — decide what a Claude session may do with sudo on merzoq.
#
# This is UX, not security. The security boundary is /etc/sudoers, built from
# security.sudo.extraRules in configuration.nix: a session that ignores this
# hook still cannot do anything the sudoers file does not already grant.
#
# What this buys instead is a fast, legible answer. Without it, `sudo <thing>`
# from a non-interactive tool call sits there waiting for a password on a TTY
# that does not exist, and the session stalls until it times out. Better to say
# no immediately, and say what to use instead.
#
#   allow   the read-only tools that genuinely need root (bounded: none write)
#   allow   castle-apply — it is gated already, by an ntfy tap on the phone,
#           and that gate is the one that counts. Prompting here as well would
#           only mean approving the same action twice.
#   deny    everything else, with a pointer to castle-apply.
#
# Added 2026-08-23. See the sudo section of configuration.nix.

set -u

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

decide() {
  jq -nc --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse",
                           permissionDecision: $d,
                           permissionDecisionReason: $r}}'
  exit 0
}

# Pull out the program name of every sudo that sits in *command* position --
# start of a line, or just after ; & | && || ( $( -- and nothing else. Matching
# a bare "sudo" anywhere would deny `git commit -m "add sudo rules"`, which is
# both wrong and the kind of wrong that is baffling in the moment.
#
# A sudo inside quotes that still looks like command position (echo "x; sudo y")
# is denied. That is rare, and denying is the safe direction to be wrong in.
invocations=$(printf '%s' "$cmd" \
  | grep -oE '(^|[;&|(])[[:space:]]*sudo[[:space:]]+[^;&|)]*' \
  | sed -E 's/.*sudo[[:space:]]+//')

# No real invocation: stay out of the way, let the normal permission flow decide.
[ -n "$invocations" ] || exit 0

# Every one of them has to name something granted -- a compound like
# `sudo dmesg && sudo rm -rf /` must not ride in on the strength of its first half.
denied=""
granted=""
while IFS= read -r rest; do
  [ -n "$rest" ] || continue
  read -ra tokens <<< "$rest"

  # Step over sudo's own harmless flags to find the program. Only -n and -k
  # are stepped over: everything else that starts with a dash changes who or
  # what sudo runs as (-u, -g, -E, -i, -s) and is a decision in its own right,
  # so it falls through and is denied on its own name.
  prog=""
  for t in "${tokens[@]}"; do
    case $t in
      -n | -k | --non-interactive | --reset-timestamp) continue ;;
      *) prog=$t; break ;;
    esac
  done

  case ${prog##*/} in
    castle-apply | smartctl | dmesg | nvme | nix-store) granted=1 ;;
    "") ;;                       # `sudo -n` with no command: harmless no-op
    *) denied=$prog ;;
  esac
done <<EOF
$invocations
EOF

if [ -n "$denied" ]; then
  decide deny "sudo $denied is not granted on merzoq, and asking for it will
just block on a password prompt with no TTY to type into.

Root-only reads, already granted, no approval needed:
  sudo smartctl / dmesg / nvme smart-log / nix-store --verify --check-contents
(journalctl, systemctl status and tailscale status need no sudo on this box.)

To change the system, use the gated wrapper -- it shows a diff, build-checks
it, and waits for Approve on the phone:
  sudo castle-apply install <staged-file> /etc/nixos/<name>.nix
  sudo castle-apply rebuild [switch|boot|test|dry-activate]
  sudo castle-apply restart <unit>

Anything outside that needs a password, typed at the machine."
fi

# Only claim "allow" for something actually granted. A bare `sudo -n` names no
# program, so there is nothing to have an opinion about -- fall through.
[ -n "$granted" ] || exit 0

decide allow "granted by security.sudo.extraRules on merzoq; castle-apply asks the phone before it acts"
