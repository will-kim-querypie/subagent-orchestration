#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/skills/subagent-orchestration"
PLUGIN_DIR="$ROOT_DIR/plugins/subagent-orchestration"

# shellcheck source=scripts/test-lib.sh
source "$ROOT_DIR/scripts/test-lib.sh"

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

resolve_git_dir() {
  local workdir="$1"
  (
    cd "$workdir"
    local git_dir
    git_dir="$(git rev-parse --git-dir)"
    cd "$git_dir"
    pwd -P
  )
}

require_file "$ROOT_DIR/.claude-plugin/marketplace.json"
require_file "$PLUGIN_DIR/.claude-plugin/plugin.json"
require_file "$SKILL_DIR/SKILL.md"
require_dir "$SKILL_DIR/scripts"
require_dir "$SKILL_DIR/references"
require_dir "$SKILL_DIR/references/review-profiles"
require_dir "$SKILL_DIR/config"
require_symlink "$PLUGIN_DIR/skills/subagent-orchestration"
require_file "$SKILL_DIR/references/review-profiles/simplify.md"
require_file "$SKILL_DIR/scripts/resolve-review-profile.sh"
require_file "$SKILL_DIR/scripts/init-review-artifacts.sh"
require_file "$SKILL_DIR/scripts/cleanup-review-artifacts.sh"

bash "$ROOT_DIR/scripts/test-require-text.sh"

require_text "$ROOT_DIR/README.md" 'For Codex, global installs keep the canonical copy under `~/.agents/skills/subagent-orchestration`.'
require_text "$ROOT_DIR/README.md" 'For Claude Code, global installs materialize at `~/.claude/skills/subagent-orchestration`.'
require_text "$ROOT_DIR/README.md" "mkdir -p ~/.claude/skills"
require_text "$ROOT_DIR/README.md" '`Review profile: simplify`'
require_text "$ROOT_DIR/AGENTS.md" "~/.agents/skills/subagent-orchestration"
require_text "$ROOT_DIR/AGENTS.md" "~/.claude/skills/subagent-orchestration"

claude plugin validate "$ROOT_DIR/.claude-plugin/marketplace.json"
claude plugin validate "$PLUGIN_DIR/.claude-plugin/plugin.json"

bash "$SKILL_DIR/scripts/resolve-entry-input.sh" >/dev/null
bash "$SKILL_DIR/scripts/resolve-entry-input.sh" config >/dev/null
bash "$SKILL_DIR/scripts/print-model-mapping.sh" codex >/dev/null
bash "$SKILL_DIR/scripts/print-model-mapping.sh" claude-code >/dev/null
mapping_fixture_dir="$(canonical_dir "$(mktemp -d)")"
(
  trap 'rm -rf "$mapping_fixture_dir"' EXIT
  cp -R "$SKILL_DIR" "$mapping_fixture_dir/skill"
  fixture_config="$mapping_fixture_dir/skill/config/providers.json"
  python3 - "$fixture_config" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
data = json.loads(config_path.read_text())
data["providers"]["codex"]["roles"]["most-capable"] = (
    "gpt-5.4 xhigh fast build 2026-03-25 extra long model mapping"
)
data["providers"]["codex"]["roles"]["general-executor"] = (
    "gpt-5.4 medium fast build 2026-03-25 extra long executor mapping"
)
config_path.write_text(json.dumps(data, indent=2) + "\n")
PY
  long_mapping_output="$(bash "$mapping_fixture_dir/skill/scripts/print-model-mapping.sh" codex)"
  [[ "$long_mapping_output" == *"gpt-5.4 xhigh fast build 2026-03-25"* ]] || {
    printf 'ERROR: long most-capable mapping prefix was not preserved in banner output\n' >&2
    printf '%s\n' "$long_mapping_output" >&2
    exit 1
  }
  [[ "$long_mapping_output" == *"extra long model mapping"* ]] || {
    printf 'ERROR: long most-capable mapping suffix was not preserved in banner output\n' >&2
    printf '%s\n' "$long_mapping_output" >&2
    exit 1
  }
  [[ "$long_mapping_output" == *"gpt-5.4 medium fast build 2026-03-25"* ]] || {
    printf 'ERROR: long general-executor mapping prefix was not preserved in banner output\n' >&2
    printf '%s\n' "$long_mapping_output" >&2
    exit 1
  }
  [[ "$long_mapping_output" == *"extra long executor mapping"* ]] || {
    printf 'ERROR: long general-executor mapping suffix was not preserved in banner output\n' >&2
    printf '%s\n' "$long_mapping_output" >&2
    exit 1
  }
  [[ "$long_mapping_output" != *"…"* ]] || {
    printf 'ERROR: long model mapping banner should wrap instead of truncating\n' >&2
    printf '%s\n' "$long_mapping_output" >&2
    exit 1
  }
)

profile_path="$(bash "$SKILL_DIR/scripts/resolve-review-profile.sh" simplify)"
[[ "$profile_path" == "$SKILL_DIR/references/review-profiles/simplify.md" ]] || {
  printf 'ERROR: unexpected review profile path: %s\n' "$profile_path" >&2
  exit 1
}

if bash "$SKILL_DIR/scripts/resolve-review-profile.sh" unknown-profile >/dev/null 2>&1; then
  printf 'ERROR: resolve-review-profile should fail for unknown profiles\n' >&2
  exit 1
fi

artifacts_output="$(bash "$SKILL_DIR/scripts/init-review-artifacts.sh" demo-task)"
manifest_path="$(printf '%s\n' "$artifacts_output" | awk -F= '/^MANIFEST_PATH=/{print $2}')"
artifact_dir="$(printf '%s\n' "$artifacts_output" | awk -F= '/^ARTIFACT_DIR=/{print $2}')"
reuse_path="$(printf '%s\n' "$artifacts_output" | awk -F= '/^REUSE_FINDINGS_PATH=/{print $2}')"
quality_path="$(printf '%s\n' "$artifacts_output" | awk -F= '/^QUALITY_FINDINGS_PATH=/{print $2}')"
efficiency_path="$(printf '%s\n' "$artifacts_output" | awk -F= '/^EFFICIENCY_FINDINGS_PATH=/{print $2}')"
fixer_path="$(printf '%s\n' "$artifacts_output" | awk -F= '/^FIXER_REPORT_PATH=/{print $2}')"
repo_git_dir="$(resolve_git_dir "$ROOT_DIR")"
repo_artifact_root="$repo_git_dir/subagent-orchestration/reviews"

require_file "$manifest_path"
require_file "$reuse_path"
require_file "$quality_path"
require_file "$efficiency_path"
require_file "$fixer_path"
require_json_expr "$(cat "$manifest_path")" '
  .task_id == "demo-task" and
  .profile == "simplify" and
  .artifact_root == "'"$repo_artifact_root"'" and
  .artifact_dir == "'"$artifact_dir"'" and
  .findings.reuse == "'"$reuse_path"'" and
  .findings.quality == "'"$quality_path"'" and
  .findings.efficiency == "'"$efficiency_path"'" and
  .fixer_report == "'"$fixer_path"'"
'
case "$artifact_dir" in
  "$repo_artifact_root/"*) ;;
  *)
    printf 'ERROR: expected repo-local artifact dir, got %s\n' "$artifact_dir" >&2
    exit 1
    ;;
esac

bash "$SKILL_DIR/scripts/cleanup-review-artifacts.sh" "$manifest_path"
[[ ! -e "$artifact_dir" ]] || {
  printf 'ERROR: artifact dir still exists after cleanup: %s\n' "$artifact_dir" >&2
  exit 1
}

non_repo_workdir="$(canonical_dir "$(mktemp -d)")"
temp_root="$(canonical_dir "${TMPDIR:-/tmp}")"
(
  cd "$non_repo_workdir"
  fallback_output="$(bash "$SKILL_DIR/scripts/init-review-artifacts.sh" fallback-task)"
  fallback_manifest="$(printf '%s\n' "$fallback_output" | awk -F= '/^MANIFEST_PATH=/{print $2}')"
  fallback_artifact_dir="$(printf '%s\n' "$fallback_output" | awk -F= '/^ARTIFACT_DIR=/{print $2}')"
  require_file "$fallback_manifest"
  case "$fallback_artifact_dir" in
    "$temp_root/subagent-orchestration/"*) ;;
    *)
      printf 'ERROR: expected temp fallback artifact dir, got %s\n' "$fallback_artifact_dir" >&2
      exit 1
    ;;
  esac
  bash "$SKILL_DIR/scripts/cleanup-review-artifacts.sh" "$fallback_manifest"
  [[ ! -e "$fallback_artifact_dir" ]] || {
    printf 'ERROR: fallback artifact dir still exists after cleanup: %s\n' "$fallback_artifact_dir" >&2
    exit 1
  }
)

worktree_parent="$(canonical_dir "$(mktemp -d)")"
worktree_dir="$worktree_parent/worktree"
git -C "$ROOT_DIR" worktree add --detach "$worktree_dir" HEAD >/dev/null
(
  trap 'git -C "$ROOT_DIR" worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true; rm -rf "$worktree_parent"' EXIT
  worktree_git_dir="$(resolve_git_dir "$worktree_dir")"
  worktree_artifact_root="$worktree_git_dir/subagent-orchestration/reviews"
  worktree_output="$(cd "$worktree_dir" && bash "$SKILL_DIR/scripts/init-review-artifacts.sh" worktree-task)"
  worktree_manifest="$(printf '%s\n' "$worktree_output" | awk -F= '/^MANIFEST_PATH=/{print $2}')"
  worktree_artifact_dir="$(printf '%s\n' "$worktree_output" | awk -F= '/^ARTIFACT_DIR=/{print $2}')"
  require_file "$worktree_manifest"
  require_json_expr "$(cat "$worktree_manifest")" '
    .task_id == "worktree-task" and
    .profile == "simplify" and
    .artifact_root == "'"$worktree_artifact_root"'" and
    .artifact_dir == "'"$worktree_artifact_dir"'"
  '
  case "$worktree_artifact_dir" in
    "$worktree_artifact_root/"*) ;;
    *)
      printf 'ERROR: expected worktree-local artifact dir, got %s\n' "$worktree_artifact_dir" >&2
      exit 1
      ;;
  esac
  bash "$SKILL_DIR/scripts/cleanup-review-artifacts.sh" "$worktree_manifest"
  [[ ! -e "$worktree_artifact_dir" ]] || {
    printf 'ERROR: worktree artifact dir still exists after cleanup: %s\n' "$worktree_artifact_dir" >&2
    exit 1
  }
)

submodule_parent="$(canonical_dir "$(mktemp -d)")"
(
  trap 'rm -rf "$submodule_parent"' EXIT
  parent_repo="$submodule_parent/parent"
  submodule_dir="$parent_repo/submodule"
  mkdir -p "$parent_repo"
  cd "$parent_repo"
  git init >/dev/null
  git -c protocol.file.allow=always submodule add "$ROOT_DIR" submodule >/dev/null
  submodule_git_dir="$(resolve_git_dir "$submodule_dir")"
  submodule_artifact_root="$submodule_git_dir/subagent-orchestration/reviews"
  submodule_output="$(cd "$submodule_dir" && bash "$SKILL_DIR/scripts/init-review-artifacts.sh" submodule-task)"
  submodule_manifest="$(printf '%s\n' "$submodule_output" | awk -F= '/^MANIFEST_PATH=/{print $2}')"
  submodule_artifact_dir="$(printf '%s\n' "$submodule_output" | awk -F= '/^ARTIFACT_DIR=/{print $2}')"
  require_file "$submodule_manifest"
  require_json_expr "$(cat "$submodule_manifest")" '
    .task_id == "submodule-task" and
    .profile == "simplify" and
    .artifact_root == "'"$submodule_artifact_root"'" and
    .artifact_dir == "'"$submodule_artifact_dir"'"
  '
  case "$submodule_artifact_dir" in
    "$submodule_artifact_root/"*) ;;
    *)
      printf 'ERROR: expected submodule-local artifact dir, got %s\n' "$submodule_artifact_dir" >&2
      exit 1
      ;;
  esac
  bash "$SKILL_DIR/scripts/cleanup-review-artifacts.sh" "$submodule_manifest"
  [[ ! -e "$submodule_artifact_dir" ]] || {
    printf 'ERROR: submodule artifact dir still exists after cleanup: %s\n' "$submodule_artifact_dir" >&2
    exit 1
  }
)

npx -y skills add "$ROOT_DIR" --list >/dev/null

skills_workdir="$(canonical_dir "$(mktemp -d)")"
(
  cd "$skills_workdir"
  npx -y skills add "$ROOT_DIR" -a codex -a claude-code -y >/dev/null
  require_file "$skills_workdir/.agents/skills/subagent-orchestration/SKILL.md"
  installed_skill_dir="$skills_workdir/.agents/skills/subagent-orchestration"
  installed_profile_path="$(bash "$installed_skill_dir/scripts/resolve-review-profile.sh" simplify)"
  [[ "$installed_profile_path" == "$installed_skill_dir/references/review-profiles/simplify.md" ]] || {
    printf 'ERROR: unexpected installed profile path: %s\n' "$installed_profile_path" >&2
    exit 1
  }
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
  installed_skill_dir="$codex_home/.agents/skills/subagent-orchestration"
  installed_profile_path="$(HOME="$codex_home" bash "$installed_skill_dir/scripts/resolve-review-profile.sh" simplify)"
  [[ "$installed_profile_path" == "$installed_skill_dir/references/review-profiles/simplify.md" ]] || {
    printf 'ERROR: unexpected codex global profile path: %s\n' "$installed_profile_path" >&2
    exit 1
  }
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
  installed_skill_dir="$claude_skills_home/.claude/skills/subagent-orchestration"
  installed_profile_path="$(HOME="$claude_skills_home" bash "$installed_skill_dir/scripts/resolve-review-profile.sh" simplify)"
  [[ "$installed_profile_path" == "$installed_skill_dir/references/review-profiles/simplify.md" ]] || {
    printf 'ERROR: unexpected claude global profile path: %s\n' "$installed_profile_path" >&2
    exit 1
  }
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
  installed_skill_dir="$claude_copy_home/.claude/skills/subagent-orchestration"
  installed_profile_path="$(HOME="$claude_copy_home" bash "$installed_skill_dir/scripts/resolve-review-profile.sh" simplify)"
  [[ "$installed_profile_path" == "$installed_skill_dir/references/review-profiles/simplify.md" ]] || {
    printf 'ERROR: unexpected claude copy profile path: %s\n' "$installed_profile_path" >&2
    exit 1
  }
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
  installed_skill_dir="$plugin_json/skills/subagent-orchestration"
  installed_profile_path="$(HOME="$claude_marketplace_home" bash "$installed_skill_dir/scripts/resolve-review-profile.sh" simplify)"
  [[ "$installed_profile_path" == "$installed_skill_dir/references/review-profiles/simplify.md" ]] || {
    printf 'ERROR: unexpected plugin profile path: %s\n' "$installed_profile_path" >&2
    exit 1
  }
)

printf 'All local packaging checks passed.\n'
