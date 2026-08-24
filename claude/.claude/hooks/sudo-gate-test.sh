#!/usr/bin/env bash
# Smoke test for sudo-gate.sh.
#
# A PreToolUse hook that decides wrongly is nearly invisible. Deny too much and
# a session quietly loses commands it was granted; deny too little and the
# session sits on a password prompt with no TTY until it times out, logging
# nothing. Neither shows up as an error anywhere. Both bugs this file guards
# against were real and neither was found by reading the script:
#
#   - a bare "sudo" matched anywhere in the command, so
#     `git commit -m "add sudo rules"` was denied -- wrong, and baffling in the
#     moment because nothing in the message mentions git
#   - sudo's own flags were read as the program name, so `sudo -n smartctl`
#     became a request to run "-n". It denied the verification loop that was
#     checking whether the NOPASSWD rules worked, which is how it surfaced
#
# The security boundary is /etc/sudoers, not this hook -- see the sudo section
# of /etc/nixos/configuration.nix. What is tested here is only whether the
# answer is fast and correct.
#
# Usage: ./sudo-gate-test.sh [path-to-sudo-gate.sh]

set -uo pipefail

SCRIPT="${1:-$(dirname "$0")/sudo-gate.sh}"

if [[ ! -x "$SCRIPT" ]]; then
  echo "not executable: $SCRIPT" >&2
  exit 1
fi

pass=0
fail=0

# $1 = case name, $2 = expected decision (allow|deny|none), $3 = the Bash
# command the session would run. "none" means the hook emits nothing and lets
# the normal permission flow decide -- the right answer when no real sudo
# invocation is present.
check() {
  local name="$1" want="$2" cmd="$3" out got
  out="$(jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}' \
         | timeout 20 "$SCRIPT" 2>&1)"

  if [[ -z "$out" ]]; then
    got=none
  else
    got="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)"
    [[ -n "$got" && "$got" != null ]] || got="unparseable output: $out"
  fi

  if [[ "$got" == "$want" ]]; then
    printf 'PASS  %-42s %s\n' "$name" "$got"
    (( pass++ ))
  else
    printf 'FAIL  %-42s got=%s want=%s\n' "$name" "$got" "$want"
    (( fail++ ))
  fi
}

# ---- nothing to have an opinion about -------------------------------------
# Only sudo in *command* position counts: start of line, or after ; & | && || (
# or $(. Everything here mentions sudo without running it.
check "no sudo at all"              none  "ls -la /etc/nixos"
check "the word sudo in prose"      none  "echo 'you need sudo for that'"
check "command -v sudo"             none  "command -v sudo"
check "sudo in a commit message"    none  "git commit -m 'add sudo rules to configuration.nix'"
check "sudo in a grep pattern"      none  "grep -rn 'sudo castle-apply' ~/.claude"
check "sudo -n names no program"    none  "sudo -n"

# ---- granted: the read-only tier ------------------------------------------
# These four need root and cannot write. journalctl, systemctl status and
# tailscale status are absent on purpose -- they need no sudo on merzoq.
check "smartctl"                    allow "sudo smartctl -a /dev/nvme0n1"
check "dmesg piped to grep"         allow "sudo dmesg -T | grep -i error"
check "nvme smart-log"              allow "sudo nvme smart-log /dev/nvme0n1"
check "nix-store verify"            allow "sudo nix-store --verify --check-contents"
check "leading whitespace"          allow "   sudo dmesg -T"
check "two allowed sudos chained"   allow "sudo dmesg -T | tail -5 && sudo smartctl -H /dev/nvme0n1"

# -n and -k do not change who or what sudo runs as, so they are stepped over
# rather than read as the program name.
check "sudo -n, allowed program"    allow "sudo -n smartctl -H /dev/nvme0n1"
check "sudo -k -n, allowed program" allow "sudo -k -n dmesg -T"

# ---- granted: the gated wrapper -------------------------------------------
# Allowed rather than asked: castle-apply blocks on an ntfy tap before it acts,
# and prompting here too would mean approving the same action twice.
check "castle-apply rebuild"        allow "sudo castle-apply rebuild switch"
check "castle-apply install"        allow "sudo castle-apply install /tmp/configuration.nix.new /etc/nixos/configuration.nix"
check "castle-apply absolute path"  allow "sudo /run/current-system/sw/bin/castle-apply restart jellyfin"

# ---- denied: not granted by sudoers ---------------------------------------
check "plain rebuild"               deny  "sudo nixos-rebuild switch"
check "cp into /etc/nixos"          deny  "sudo cp /tmp/configuration.nix.new /etc/nixos/configuration.nix"
check "tee into /etc"               deny  "sudo tee /etc/nixos/configuration.nix < /tmp/x"
check "systemctl restart"           deny  "sudo systemctl restart jellyfin"
check "editor"                      deny  "sudo vim /etc/nixos/configuration.nix"
check "reading a secret"            deny  "sudo cat /var/lib/secrets/slskd.env"
check "sudo -n, denied program"     deny  "sudo -n nixos-rebuild switch"

# Any other dash flag changes who or what sudo runs as, so it is a decision in
# its own right and falls through to be denied on its own name.
check "sudo -E preserves env"       deny  "sudo -E smartctl -H /dev/nvme0n1"
check "sudo -u changes runas"       deny  "sudo -u postgres smartctl -H /dev/nvme0n1"
check "sudo -i shell"               deny  "sudo -i"
check "sudo -u postgres psql"       deny  "sudo -u postgres psql -c 'select 1'"

# ---- denied: hiding in a compound -----------------------------------------
# A denied sudo must not ride in on the strength of an allowed one earlier in
# the line.
check "allowed then denied, &&"     deny  "sudo dmesg -T && sudo rm -rf /etc/nixos"
check "allowed then denied, ;"      deny  "sudo smartctl -H /dev/nvme0n1; sudo nixos-rebuild switch"
check "denied mid-pipeline"         deny  "cat /tmp/x | sudo tee /etc/passwd"
check "inside a subshell"           deny  "(sudo chmod 777 /etc/shadow)"
check "command substitution"        deny  "x=\$(sudo cat /etc/shadow)"
check "multi-line, line two denied" deny  "sudo dmesg -T
sudo nixos-rebuild switch"

# ---- denied: near-misses on the allowlist ---------------------------------
# Matching is on the program's basename, exactly. Prefixes must not pass.
check "lookalike binary name"       deny  "sudo castle-apply-evil rebuild"
check "not-quite-nvme"              deny  "sudo nvmeXX format /dev/nvme0n1"

# ---- the deny payload has to be usable ------------------------------------
# A deny that does not say what to use instead just gets retried.
reason="$(jq -nc '{tool_name:"Bash",tool_input:{command:"sudo nixos-rebuild switch"}}' \
          | timeout 20 "$SCRIPT" 2>&1 \
          | jq -r '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null)"
if [[ "$reason" == *castle-apply* ]]; then
  printf 'PASS  %-42s %s\n' "deny explains castle-apply" "ok"; (( pass++ ))
else
  printf 'FAIL  %-42s reason lacks castle-apply\n' "deny explains castle-apply"; (( fail++ ))
fi

event="$(jq -nc '{tool_name:"Bash",tool_input:{command:"sudo dmesg -T"}}' \
         | timeout 20 "$SCRIPT" 2>&1 \
         | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)"
if [[ "$event" == PreToolUse ]]; then
  printf 'PASS  %-42s %s\n' "emits hookEventName" "$event"; (( pass++ ))
else
  printf 'FAIL  %-42s got=%s want=PreToolUse\n' "emits hookEventName" "$event"; (( fail++ ))
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
