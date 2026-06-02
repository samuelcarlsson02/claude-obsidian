#!/usr/bin/env bash
# allocate-address.sh — atomic creation-order address allocation for the vault.
#
# Reserves the next address of the form c-NNNNNN and increments the counter
# under an exclusive flock. On missing counter file, recovers by scanning the
# vault for the highest existing c-NNNNNN in page frontmatter and resuming from
# max+1. Never silently resets to 1 in a non-empty vault.
#
# Usage:
#   ./scripts/allocate-address.sh           # prints the reserved address (e.g. c-000042) to stdout
#   ./scripts/allocate-address.sh --peek    # prints the next value without incrementing
#   ./scripts/allocate-address.sh --rebuild # recomputes counter from max observed and exits
#
# Exit codes:
#   0 — success
#   1 — lock acquisition failed (another writer is holding the lock)
#   2 — vault-meta directory missing and cannot be created
#   3 — counter value corrupt or non-numeric

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COUNTER_FILE="${VAULT_ROOT}/.vault-meta/address-counter.txt"
LOCK_FILE="${VAULT_ROOT}/.vault-meta/.address.lock"
WIKI_DIR="${VAULT_ROOT}/wiki"

MODE="${1:-allocate}"

mkdir -p "$(dirname "$COUNTER_FILE")" || {
  echo "ERR: cannot create .vault-meta/" >&2
  exit 2
}

# Acquire an exclusive lock with a ~5-second timeout.
#
# flock(1) is preferred (kernel-level, auto-releases when the process exits),
# but it is unavailable on some platforms — notably Git for Windows / MSYS2,
# which ship no util-linux flock. There we fall back to an atomic mkdir
# spinlock (mkdir is atomic on every POSIX-ish filesystem) with an age-based
# stale reaper so a crashed holder can't deadlock the vault, released via an
# EXIT trap. Set VAULT_LOCK_NO_FLOCK=1 to force the fallback (lets
# flock-capable CI exercise the portable path).
LOCK_DIR="${VAULT_ROOT}/.vault-meta/.address.lock.d"

_use_flock() { [ -z "${VAULT_LOCK_NO_FLOCK:-}" ] && command -v flock >/dev/null 2>&1; }

if _use_flock; then
  exec 9>"$LOCK_FILE"
  if ! flock -x -w 5 9; then
    echo "ERR: could not acquire address allocator lock within 5s" >&2
    exit 1
  fi
else
  # Keep the spin hot path cheap: a bare mkdir + sleep. The stale-reaper check
  # forks date+stat, which is costly (especially on MSYS), so only run it every
  # ~1s rather than every iteration — otherwise heavy same-lock contention can
  # starve waiters. The budget is generous because it only spins when contended;
  # an uncontended caller wins the first mkdir and never sleeps.
  _waited=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    _waited=$((_waited + 1))
    if [ $((_waited % 20)) -eq 0 ] && [ -d "$LOCK_DIR" ]; then
      _now=$(date +%s 2>/dev/null || echo 0)
      _mt=$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || echo "$_now")
      if [ "$((_now - _mt))" -ge 30 ]; then rm -rf "$LOCK_DIR" 2>/dev/null; continue; fi
    fi
    if [ "$_waited" -ge 600 ]; then
      echo "ERR: could not acquire address allocator lock" >&2
      exit 1
    fi
    sleep 0.05
  done
  trap 'rm -rf "$LOCK_DIR" 2>/dev/null' EXIT
fi

scan_max_c_address() {
  # Emit the largest NNNNNN from "address: c-NNNNNN" lines that appear inside
  # the FIRST YAML frontmatter block of each wiki .md file. Code-block examples
  # and body prose are excluded. Returns 0 if none found.
  if [ ! -d "$WIKI_DIR" ]; then
    echo 0
    return
  fi
  find "$WIKI_DIR" -type f -name '*.md' -print0 2>/dev/null \
    | xargs -0 awk '
        FNR == 1 { state = "pre"; next_is_fm = ($0 == "---") ? 1 : 0 }
        FNR == 1 && $0 == "---" { state = "fm"; next }
        state == "fm" && $0 == "---" { state = "body"; nextfile }
        state == "fm" && match($0, /^address:[[:space:]]+c-[0-9]{6}[[:space:]]*$/) {
          if (match($0, /c-[0-9]{6}/)) {
            print substr($0, RSTART, RLENGTH)
          }
        }
      ' 2>/dev/null \
    | sed 's/^c-0*//;s/^$/0/' \
    | sort -n \
    | tail -1 \
    | awk 'BEGIN{n=0} {n=$0} END{print (n+0)}'
}

read_or_recover_counter() {
  if [ ! -f "$COUNTER_FILE" ]; then
    local max_c
    max_c="$(scan_max_c_address)"
    echo $((max_c + 1)) > "$COUNTER_FILE"
    echo "INFO: counter file missing; recovered from vault scan, set to $((max_c + 1))" >&2
  fi
  local raw
  raw="$(cat "$COUNTER_FILE")"
  if ! [[ "$raw" =~ ^[0-9]+$ ]]; then
    echo "ERR: counter file content is not a positive integer: $raw" >&2
    exit 3
  fi
  echo "$raw"
}

case "$MODE" in
  --peek)
    read_or_recover_counter
    ;;
  --rebuild)
    max_c="$(scan_max_c_address)"
    echo $((max_c + 1)) > "$COUNTER_FILE"
    echo "Counter rebuilt: next = $((max_c + 1))"
    ;;
  allocate|"")
    current="$(read_or_recover_counter)"
    next=$((current + 1))
    echo "$next" > "$COUNTER_FILE"
    printf 'c-%06d\n' "$current"
    ;;
  *)
    echo "ERR: unknown mode: $MODE" >&2
    echo "Usage: $0 [allocate|--peek|--rebuild]" >&2
    exit 3
    ;;
esac
