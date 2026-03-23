#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

looks_like_path() {
  local value="$1"

  [[ "$value" == /* ]] && return 0
  [[ "$value" == ./* ]] && return 0
  [[ "$value" == ../* ]] && return 0
  [[ "$value" == ~/* ]] && return 0
  [[ "$value" == */* ]] && return 0
  [[ "$value" == *.md ]] && return 0
  [[ "$value" == *.markdown ]] && return 0
  [[ "$value" == *.txt ]] && return 0
  [[ "$value" == *.rst ]] && return 0
  [[ "$value" == *.adoc ]] && return 0

  return 1
}

if [[ $# -gt 1 ]]; then
  fail "expected zero or one argument"
fi

raw_input="${1-}"
trimmed_input="${raw_input//[[:space:]]/}"

if [[ -z "$trimmed_input" ]]; then
  printf 'INPUT_MODE=conversation\n'
  exit 0
fi

if [[ "$raw_input" == "config" ]]; then
  printf 'INPUT_MODE=config\n'
  exit 0
fi

candidate="$raw_input"
if [[ "$candidate" == ~/* ]]; then
  candidate="${HOME}/${candidate#~/}"
fi

if [[ -e "$candidate" ]]; then
  [[ -f "$candidate" ]] || fail "path exists but is not a regular file: $raw_input"
  [[ -r "$candidate" ]] || fail "file is not readable: $raw_input"
  [[ -s "$candidate" ]] || fail "file is empty: $raw_input"

  abs_path="$(cd "$(dirname "$candidate")" && pwd)/$(basename "$candidate")"

  printf 'INPUT_MODE=plan_file\n'
  printf 'RESOLVED_PATH=%s\n' "$abs_path"
  printf '__SUBAGENT_ORCHESTRATION_CONTENT_BEGIN__\n'
  cat "$abs_path"
  printf '\n__SUBAGENT_ORCHESTRATION_CONTENT_END__\n'
  exit 0
fi

if looks_like_path "$raw_input"; then
  fail "input looks like a file path but was not found: $raw_input"
fi

printf 'INPUT_MODE=instructions\n'
printf '__SUBAGENT_ORCHESTRATION_CONTENT_BEGIN__\n'
printf '%s\n' "$raw_input"
printf '__SUBAGENT_ORCHESTRATION_CONTENT_END__\n'
