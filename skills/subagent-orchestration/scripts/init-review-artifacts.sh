#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

sanitize_token() {
  local value="$1"
  local sanitized

  sanitized="$(printf '%s' "$value" | tr -cs 'A-Za-z0-9._-' '-')"
  sanitized="${sanitized#-}"
  sanitized="${sanitized%-}"

  if [[ -z "$sanitized" ]]; then
    sanitized="review"
  fi

  printf '%s\n' "$sanitized"
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  fail "expected task id and optional review profile"
fi

task_id="$1"
profile_name="${2:-simplify}"
safe_task_id="$(sanitize_token "$task_id")"

bash "$SCRIPT_DIR/resolve-review-profile.sh" "$profile_name" >/dev/null

if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  artifact_root="$git_root/.git/subagent-orchestration/reviews"
  artifact_scope="repo"
else
  artifact_root="${TMPDIR:-/tmp}/subagent-orchestration"
  artifact_scope="temp"
fi

mkdir -p "$artifact_root"
artifact_dir="$(mktemp -d "$artifact_root/${safe_task_id}-XXXXXX")"

manifest_path="$artifact_dir/manifest.json"
reuse_path="$artifact_dir/reuse.md"
quality_path="$artifact_dir/quality.md"
efficiency_path="$artifact_dir/efficiency.md"
fixer_report_path="$artifact_dir/fixer-report.md"

touch "$reuse_path" "$quality_path" "$efficiency_path" "$fixer_report_path"

jq -n \
  --arg task_id "$task_id" \
  --arg profile "$profile_name" \
  --arg artifact_scope "$artifact_scope" \
  --arg artifact_dir "$artifact_dir" \
  --arg reuse "$reuse_path" \
  --arg quality "$quality_path" \
  --arg efficiency "$efficiency_path" \
  --arg fixer_report "$fixer_report_path" \
  '{
    task_id: $task_id,
    profile: $profile,
    artifact_scope: $artifact_scope,
    artifact_dir: $artifact_dir,
    findings: {
      reuse: $reuse,
      quality: $quality,
      efficiency: $efficiency
    },
    fixer_report: $fixer_report
  }' >"$manifest_path"

printf 'ARTIFACT_SCOPE=%s\n' "$artifact_scope"
printf 'ARTIFACT_DIR=%s\n' "$artifact_dir"
printf 'MANIFEST_PATH=%s\n' "$manifest_path"
printf 'REUSE_FINDINGS_PATH=%s\n' "$reuse_path"
printf 'QUALITY_FINDINGS_PATH=%s\n' "$quality_path"
printf 'EFFICIENCY_FINDINGS_PATH=%s\n' "$efficiency_path"
printf 'FIXER_REPORT_PATH=%s\n' "$fixer_report_path"
