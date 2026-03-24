#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

if [[ $# -ne 1 ]]; then
  fail "expected one review profile name"
fi

profile_name="$1"

case "$profile_name" in
  simplify)
    profile_path="$SKILL_DIR/references/review-profiles/simplify.md"
    [[ -f "$profile_path" ]] || fail "missing bundled review profile: $profile_name"
    printf '%s\n' "$profile_path"
    ;;
  *)
    fail "unknown review profile: $profile_name"
    ;;
esac
