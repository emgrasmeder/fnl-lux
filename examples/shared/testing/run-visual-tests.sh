#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
VISUAL_DIR="${1:-.}"

if [[ ! -d "$VISUAL_DIR" ]]; then
  echo "run-visual-tests.sh: directory not found: $VISUAL_DIR" >&2
  exit 2
fi

cd "$VISUAL_DIR"

if ! command -v love >/dev/null 2>&1; then
  echo "run-visual-tests: love not found on PATH" >&2
  exit 2
fi

if [ -n "${DISPLAY:-}" ]; then
  RUN=(love .)
elif command -v xvfb-run >/dev/null 2>&1; then
  RUN=(xvfb-run -a love .)
else
  RUN=(love .)
fi

if [ "${UPDATE_VISUAL_FIXTURES:-}" = "1" ]; then
  exec "${RUN[@]}" -- --update-fixtures
else
  exec "${RUN[@]}"
fi
