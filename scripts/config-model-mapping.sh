#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -ne 0 ]]; then
  printf 'ERROR: this command does not accept extra arguments\n' >&2
  exit 1
fi

python3 "$SCRIPT_DIR/model-mapping.py" interactive-config
