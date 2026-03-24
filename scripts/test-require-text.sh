#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=scripts/test-lib.sh
source "$ROOT_DIR/scripts/test-lib.sh"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

link_tool() {
  local tool_dir="$1"
  local tool_name="$2"
  local tool_path

  tool_path="$(command -v "$tool_name" || true)"
  [[ -n "$tool_path" ]] || fail "required tool not found on host: $tool_name"
  ln -s "$tool_path" "$tool_dir/$tool_name"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_path="$tmp_dir/fixture.txt"
tool_dir="$tmp_dir/bin"
mkdir -p "$tool_dir"

printf 'For Codex, global installs keep the canonical copy under `~/.agents/skills/subagent-orchestration`.\n' >"$fixture_path"

link_tool "$tool_dir" grep

PATH="$tool_dir" require_text \
  "$fixture_path" \
  'For Codex, global installs keep the canonical copy under `~/.agents/skills/subagent-orchestration`.'

if PATH="$tool_dir" require_text "$fixture_path" 'missing text' >/dev/null 2>&1; then
  fail "require_text should fail when the text is absent"
fi

printf 'Portable text matching checks passed.\n'
