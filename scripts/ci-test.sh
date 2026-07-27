#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${FNL_LUX_CI_IMAGE:-fnl-lux-ci:local}"
VISUAL_DIR="$ROOT/examples/shared/character/visual"

podman build -t "$IMAGE" -f "$ROOT/Containerfile" "$ROOT"
podman run --rm \
  -v "$ROOT:/work:Z" \
  -w /work \
  -e DEPS_NO_PROMPT=true \
  "$IMAGE" \
  bash -lc 'deps --profiles dev --no-prompt tasks/run-tests && bash examples/shared/testing/run-all-visual-tests.sh'
