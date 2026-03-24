#!/usr/bin/env bash

require_text() {
  local path="$1"
  local pattern="$2"

  if command -v rg >/dev/null 2>&1; then
    rg -q --fixed-strings "$pattern" "$path" && return 0
  elif command -v grep >/dev/null 2>&1; then
    grep -F -q -- "$pattern" "$path" && return 0
  else
    printf 'ERROR: no supported text matcher found (need rg or grep)\n' >&2
    return 1
  fi

  printf 'ERROR: missing text in %s: %s\n' "$path" "$pattern" >&2
  return 1
}
