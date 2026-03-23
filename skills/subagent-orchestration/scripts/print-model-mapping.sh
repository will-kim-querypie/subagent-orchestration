#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -ne 1 ]]; then
  printf 'ERROR: expected provider key, e.g. claude-code or codex\n' >&2
  exit 1
fi

python3 "$SCRIPT_DIR/model-mapping.py" print-banner "$1"
