#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

run_one() {
  local dir="$1"
  if [[ ! -x "$dir/tasks/run-visual-tests" ]]; then
    echo "run-all-visual-tests: missing $dir/tasks/run-visual-tests" >&2
    return 1
  fi
  echo "== visual tests: $dir"
  (cd "$dir" && deps --lua-version 5.1 --no-prompt && ./tasks/run-visual-tests)
}

run_one "examples/shared/character/visual"

for dir in examples/*/visual; do
  [[ -d "$dir" ]] || continue
  [[ "$dir" == "examples/shared/character/visual" ]] && continue
  run_one "$dir"
done
