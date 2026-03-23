#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/skills/subagent-orchestration"
PLUGIN_DIR="$ROOT_DIR/plugins/subagent-orchestration"

require_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    printf 'ERROR: missing file: %s\n' "$path" >&2
    exit 1
  }
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || {
    printf 'ERROR: missing directory: %s\n' "$path" >&2
    exit 1
  }
}

require_file "$ROOT_DIR/.claude-plugin/marketplace.json"
require_file "$PLUGIN_DIR/.claude-plugin/plugin.json"
require_file "$SKILL_DIR/SKILL.md"
require_dir "$SKILL_DIR/scripts"
require_dir "$SKILL_DIR/references"
require_dir "$SKILL_DIR/config"
[[ -L "$PLUGIN_DIR/skills/subagent-orchestration" ]] || {
  printf 'ERROR: expected symlinked plugin skill wrapper at %s\n' "$PLUGIN_DIR/skills/subagent-orchestration" >&2
  exit 1
}

claude plugin validate "$ROOT_DIR/.claude-plugin/marketplace.json"
claude plugin validate "$PLUGIN_DIR/.claude-plugin/plugin.json"

bash "$SKILL_DIR/scripts/resolve-entry-input.sh" >/dev/null
bash "$SKILL_DIR/scripts/resolve-entry-input.sh" config >/dev/null
bash "$SKILL_DIR/scripts/print-model-mapping.sh" codex >/dev/null
bash "$SKILL_DIR/scripts/print-model-mapping.sh" claude-code >/dev/null

npx -y skills add "$ROOT_DIR" --list >/dev/null

skills_workdir="$(mktemp -d)"
(
  cd "$skills_workdir"
  npx -y skills add "$ROOT_DIR" -a codex -a claude-code -y >/dev/null
  require_file "$skills_workdir/.agents/skills/subagent-orchestration/SKILL.md"
)

claude_home="$(mktemp -d)"
claude_workdir="$(mktemp -d)"
(
  cd "$claude_workdir"
  HOME="$claude_home" claude plugin marketplace add "$ROOT_DIR" >/dev/null
  HOME="$claude_home" claude plugin install subagent-orchestration@subagent-orchestration --scope local >/dev/null
  plugin_json="$(HOME="$claude_home" claude plugin list --json | jq -r '.[] | select(.id=="subagent-orchestration@subagent-orchestration") | .installPath')"
  [[ -n "$plugin_json" && "$plugin_json" != "null" ]] || {
    printf 'ERROR: plugin install path not found in claude plugin list output\n' >&2
    exit 1
  }
  require_file "$plugin_json/skills/subagent-orchestration/SKILL.md"
)

printf 'All local packaging checks passed.\n'
