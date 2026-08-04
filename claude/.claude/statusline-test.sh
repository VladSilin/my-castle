#!/usr/bin/env bash
# Smoke test for statusline.sh.
#
# Claude Code renders a status line command that exits non-zero as *nothing*.
# There is no error surfaced anywhere, so a broken status line looks identical
# to a disabled one. Every bug this file guards against shipped silently and was
# only noticed later:
#
#   - `set -e` + a bare `(( x = 0 ))`, which returns exit status 1 when the
#     result is zero, aborting the script at 0% context usage
#   - a fractional used_percentage, which bash arithmetic cannot parse
#   - GNU vs BSD `stat` disagreeing, with the losing side writing its error to
#     stdout where it landed inside $(( ))
#
# The bar is deliberately low: exit 0 and emit something. That is exactly the
# property Claude Code depends on, and the one that kept breaking.
#
# Usage: ./statusline-test.sh [path-to-statusline.sh]

set -uo pipefail

SCRIPT="${1:-$(dirname "$0")/statusline.sh}"

if [[ ! -x "$SCRIPT" ]]; then
  echo "not executable: $SCRIPT" >&2
  exit 1
fi

pass=0
fail=0

# $1 = case name, $2 = JSON (or arbitrary text) delivered on stdin
check() {
  local name="$1" payload="$2" out code
  out="$(printf '%s' "$payload" | timeout 20 "$SCRIPT" 2>&1)"
  code=$?

  if (( code != 0 )); then
    printf 'FAIL  %-22s exit=%d\n' "$name" "$code"
    printf '        %s\n' "${out:-<no output>}"
    (( ++fail ))
    return
  fi

  if [[ -z "${out//[[:space:]]/}" ]]; then
    printf 'FAIL  %-22s exit=0 but produced no output\n' "$name"
    (( ++fail ))
    return
  fi

  printf 'ok    %-22s %s\n' "$name" "$(printf '%s' "$out" | head -1 | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-46)"
  (( ++pass ))
}

ctx() { # $1 = window size, $2 = used percentage, $3 = cost
  printf '{"model":{"display_name":"Test Model"},"context_window":{"context_window_size":%s,"used_percentage":%s},"cost":{"total_cost_usd":%s},"session_id":"smoketest"}' "$1" "$2" "$3"
}

check "normal"            "$(ctx 1000000 42 1.23)"
check "zero percent"      "$(ctx 1000000 0 0)"        # bare (( )) returning 0 under set -e
check "fractional pct"    "$(ctx 1000000 12.7 1.5)"   # bash has no floats
check "over 100 pct"      "$(ctx 200000 140 3)"
check "null fields"       '{"model":{"display_name":"X"},"context_window":{"context_window_size":null,"used_percentage":null},"cost":{"total_cost_usd":null},"session_id":"smoketest"}'
check "missing keys"      '{"session_id":"smoketest"}'
check "empty object"      '{}'
check "invalid json"      'not json at all'
check "empty stdin"       ''

# The monthly-cost cache is read through stat, whose flags differ between GNU
# and BSD. Both states have to work: the bug that broke this only appeared once
# the cache file existed, so testing the empty state alone proved nothing.
CACHE="$HOME/.claude/monthly_cost_cache"
if [[ -f "$CACHE" ]]; then
  check "cache present"   "$(ctx 1000000 42 1.23)"
  backup="$(mktemp)"; cp "$CACHE" "$backup"; rm -f "$CACHE"
  check "cache absent"    "$(ctx 1000000 42 1.23)"
  cp "$backup" "$CACHE"; rm -f "$backup"
else
  check "cache absent"    "$(ctx 1000000 42 1.23)"
  printf '0.00' > "$CACHE"
  check "cache present"   "$(ctx 1000000 42 1.23)"
  rm -f "$CACHE"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
