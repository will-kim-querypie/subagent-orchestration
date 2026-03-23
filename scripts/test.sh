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

require_symlink() {
  local path="$1"
  [[ -L "$path" ]] || {
    printf 'ERROR: expected symlink: %s\n' "$path" >&2
    exit 1
  }
}

require_not_symlink() {
  local path="$1"
  [[ ! -L "$path" ]] || {
    printf 'ERROR: expected regular directory or file, got symlink: %s\n' "$path" >&2
    exit 1
  }
}

require_text() {
  local path="$1"
  local pattern="$2"
  rg -q --fixed-strings "$pattern" "$path" || {
    printf 'ERROR: missing text in %s: %s\n' "$path" "$pattern" >&2
    exit 1
  }
}

require_json_expr() {
  local json="$1"
  local expression="$2"
  jq -e "$expression" >/dev/null <<<"$json" || {
    printf 'ERROR: JSON assertion failed: %s\n' "$expression" >&2
    printf '%s\n' "$json" >&2
    exit 1
  }
}

canonical_dir() {
  local path="$1"
  (
    cd "$path"
    pwd -P
  )
}

require_file "$ROOT_DIR/.claude-plugin/marketplace.json"
require_file "$PLUGIN_DIR/.claude-plugin/plugin.json"
require_file "$SKILL_DIR/SKILL.md"
require_dir "$SKILL_DIR/scripts"
require_dir "$SKILL_DIR/references"
require_dir "$SKILL_DIR/config"
require_symlink "$PLUGIN_DIR/skills/subagent-orchestration"

require_text "$ROOT_DIR/README.md" 'For Codex, global installs keep the canonical copy under `~/.agents/skills/subagent-orchestration`.'
require_text "$ROOT_DIR/README.md" 'For Claude Code, global installs materialize at `~/.claude/skills/subagent-orchestration`.'
require_text "$ROOT_DIR/README.md" "mkdir -p ~/.claude/skills"
require_text "$ROOT_DIR/AGENTS.md" "~/.agents/skills/subagent-orchestration"
require_text "$ROOT_DIR/AGENTS.md" "~/.claude/skills/subagent-orchestration"

claude plugin validate "$ROOT_DIR/.claude-plugin/marketplace.json"
claude plugin validate "$PLUGIN_DIR/.claude-plugin/plugin.json"

bash "$SKILL_DIR/scripts/resolve-entry-input.sh" >/dev/null
bash "$SKILL_DIR/scripts/resolve-entry-input.sh" config >/dev/null
bash "$SKILL_DIR/scripts/print-model-mapping.sh" codex >/dev/null
bash "$SKILL_DIR/scripts/print-model-mapping.sh" claude-code >/dev/null

npx -y skills add "$ROOT_DIR" --list >/dev/null

skills_workdir="$(canonical_dir "$(mktemp -d)")"
(
  cd "$skills_workdir"
  npx -y skills add "$ROOT_DIR" -a codex -a claude-code -y >/dev/null
  require_file "$skills_workdir/.agents/skills/subagent-orchestration/SKILL.md"
  local_json="$(npx -y skills ls --json)"
  require_json_expr "$local_json" '
    length >= 1 and
    any(.[];
      .name == "subagent-orchestration" and
      .path == "'"$skills_workdir"'/.agents/skills/subagent-orchestration"
    )
  '
)

codex_home="$(canonical_dir "$(mktemp -d)")"
codex_workdir="$(canonical_dir "$(mktemp -d)")"
(
  cd "$codex_workdir"
  HOME="$codex_home" npx -y skills add "$ROOT_DIR" -a codex -g -y >/dev/null
  require_file "$codex_home/.agents/skills/subagent-orchestration/SKILL.md"
  codex_json="$(HOME="$codex_home" npx -y skills ls -g -a codex --json)"
  require_json_expr "$codex_json" '
    length == 1 and
    .[0].name == "subagent-orchestration" and
    .[0].path == "'"$codex_home"'/.agents/skills/subagent-orchestration"
  '
)

claude_skills_home="$(canonical_dir "$(mktemp -d)")"
claude_skills_workdir="$(canonical_dir "$(mktemp -d)")"
(
  mkdir -p "$claude_skills_home/.claude/skills"
  cd "$claude_skills_workdir"
  HOME="$claude_skills_home" npx -y skills add "$ROOT_DIR" -a claude-code -g -y >/dev/null
  require_dir "$claude_skills_home/.claude/skills/subagent-orchestration"
  require_not_symlink "$claude_skills_home/.claude/skills/subagent-orchestration"
  require_file "$claude_skills_home/.claude/skills/subagent-orchestration/SKILL.md"
  claude_json="$(HOME="$claude_skills_home" npx -y skills ls -g -a claude-code --json)"
  require_json_expr "$claude_json" '
    length == 1 and
    .[0].name == "subagent-orchestration" and
    .[0].path == "'"$claude_skills_home"'/.claude/skills/subagent-orchestration" and
    (.[0].agents | index("Claude Code")) != null
  '
)

claude_copy_home="$(canonical_dir "$(mktemp -d)")"
claude_copy_workdir="$(canonical_dir "$(mktemp -d)")"
(
  mkdir -p "$claude_copy_home/.claude/skills"
  cd "$claude_copy_workdir"
  HOME="$claude_copy_home" npx -y skills add "$ROOT_DIR" -a claude-code -g --copy -y >/dev/null
  require_dir "$claude_copy_home/.claude/skills/subagent-orchestration"
  require_not_symlink "$claude_copy_home/.claude/skills/subagent-orchestration"
  require_file "$claude_copy_home/.claude/skills/subagent-orchestration/SKILL.md"
  claude_copy_json="$(HOME="$claude_copy_home" npx -y skills ls -g -a claude-code --json)"
  require_json_expr "$claude_copy_json" '
    length == 1 and
    .[0].name == "subagent-orchestration" and
    .[0].path == "'"$claude_copy_home"'/.claude/skills/subagent-orchestration" and
    (.[0].agents | index("Claude Code")) != null
  '
)

claude_marketplace_home="$(canonical_dir "$(mktemp -d)")"
claude_marketplace_workdir="$(canonical_dir "$(mktemp -d)")"
(
  cd "$claude_marketplace_workdir"
  HOME="$claude_marketplace_home" claude plugin marketplace add "$ROOT_DIR" >/dev/null
  HOME="$claude_marketplace_home" claude plugin install subagent-orchestration@subagent-orchestration --scope local >/dev/null
  plugin_json="$(HOME="$claude_marketplace_home" claude plugin list --json | jq -r '.[] | select(.id=="subagent-orchestration@subagent-orchestration") | .installPath')"
  [[ -n "$plugin_json" && "$plugin_json" != "null" ]] || {
    printf 'ERROR: plugin install path not found in claude plugin list output\n' >&2
    exit 1
  }
  require_file "$plugin_json/skills/subagent-orchestration/SKILL.md"
)

printf 'All local packaging checks passed.\n'
