#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

if [[ $# -ne 1 ]]; then
  fail "expected one manifest path"
fi

manifest_path="$1"
[[ -f "$manifest_path" ]] || fail "manifest file not found: $manifest_path"

artifact_root="$(jq -r '.artifact_root // empty' "$manifest_path")"
artifact_dir="$(jq -r '.artifact_dir // empty' "$manifest_path")"
[[ -n "$artifact_dir" ]] || fail "manifest has no artifact_dir"
[[ -d "$artifact_dir" ]] || fail "artifact dir not found: $artifact_dir"

manifest_dir="$(cd "$(dirname "$manifest_path")" && pwd -P)"
artifact_dir_real="$(cd "$artifact_dir" && pwd -P)"

[[ "$manifest_dir" == "$artifact_dir_real" ]] || fail "manifest is not stored in the artifact dir"

if [[ -n "$artifact_root" ]]; then
  artifact_root_real="$(cd "$artifact_root" && pwd -P)"
  case "$artifact_dir_real" in
    "$artifact_root_real"/*) ;;
    *)
      fail "artifact dir is not stored under artifact_root: $artifact_dir_real"
      ;;
  esac
else
  temp_root="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
  case "$artifact_dir_real" in
    */.git/subagent-orchestration/reviews/*) ;;
    "$temp_root"/subagent-orchestration/*) ;;
    *)
      fail "refusing to remove unexpected artifact dir: $artifact_dir_real"
      ;;
  esac
fi

rm -rf "$artifact_dir_real"
printf 'CLEANED=%s\n' "$artifact_dir_real"
