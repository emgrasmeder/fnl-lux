# Shared example utilities

Love2D example games import helpers from here instead of copying them. Module resolution uses `"../?.fnl"` in each example's **production** [`main.lua`](examples/tic-tac-toe/main.lua) fennel path and the dev profile in `deps.fnl`:

```fennel
(require :shared.grid)
(require :shared.love-ui)
(require :shared.testing.startup)
```

The canonical production path string lives in [`testing/startup.fnl`](examples/shared/testing/startup.fnl) as `PRODUCTION-FENNEL-PATH`. Keep every example `main.lua` in sync with it.

## Modules

| Module                  | Require path                | Purpose                                                                                                         |
|-------------------------|-----------------------------|-----------------------------------------------------------------------------------------------------------------|
| `grid.fnl`              | `:shared.grid`              | Grid math (`pos-key`, `cell-bounds-at`, window size, `build-cell-grid`)                                         |
| `love-ui.fnl`           | `:shared.love-ui`           | Love2D drawing primitives (background, line grid, filled rects, centered text, overlays)                        |
| `character/render.fnl`  | `:shared.character.render`  | Stick figure drawing with walk-cycle leg poses                                                                    |
| `character/walk.fnl`    | `:shared.character.walk`    | Walk phase accumulation and foot placement (`advance-walk-state`, `foot-positions`)                               |
| `audio.fnl`             | `:shared.audio`             | Procedural tone generation (`make-tone`, `make-lazy-player`)                                                    |
| `util.fnl`              | `:shared.util`              | `shuffle!`, `positions-equal?`, `point-in-rect?`                                                                |
| `tick.fnl`              | `:shared.tick`              | Fixed-interval game step timer (`step-on-interval`)                                                             |
| `testing/love-mock.fnl` | `:shared.testing.love-mock` | Headless Love2D stub for CI (configurable mouse/keyboard)                                                      |
| `testing/visual-compare.fnl` | `:shared.testing.visual-compare` | PNG fixture load/save and pixel compare for Love golden tests                                           |
| `testing/visual-runner.fnl` | `:shared.testing.visual-runner` | Shared `love.load` / `love.draw` harness for game `visual/` golden tests (`make-loop`, canvas capture) |
| `testing/discover.fnl`  | `:shared.testing.discover`  | Discover Love2D example dirs; run per-example shell commands                                                    |
| `testing/startup.fnl`   | `:shared.testing.startup`   | Smoke-test `love.load` / `love.update` / `love.draw` using production fennel paths                              |

## Testing layers

1. **Unit tests (fennel-test, no Love binary)** — Game logic in `systems.fnl` / `world.fnl`; input as coordinates or keys. Run via each example’s `tasks/run-tests` or root `deps --profiles dev tasks/run-tests`.
2. **Startup smoke (`love-mock`)** — Every example’s `tests/startup-test.fnl` calls `shared.testing.startup/run!` to load `main.fnl` headlessly.
3. **Golden renders (Love + hidden window)** — Each game example (except shared-renderer exempt `keep-going-right`) has `visual/` with scenario-driven renders and PNG fixtures. Implement `visual/main.fnl` with `:shared.testing.visual-runner` (`make-loop`, `capture-window`, `finish-capture`); compare helpers live in [`testing/visual-compare.fnl`](examples/shared/testing/visual-compare.fnl). CI runs [`testing/run-all-visual-tests.sh`](examples/shared/testing/run-all-visual-tests.sh) after fennel-test (Love + xvfb in the container; native macOS falls back to plain `love` when xvfb is unavailable).

**Run all visual tests locally:**

```bash
bash examples/shared/testing/run-all-visual-tests.sh
```

**Refresh PNG baselines** (prefer Linux podman CI image so pixels match CI):

```bash
UPDATE_VISUAL_FIXTURES=1 bash examples/shared/testing/run-all-visual-tests.sh
```

## New Love2D example checklist

1. Add `../?.fnl` to fennel `path` in `main.lua` (match `PRODUCTION-FENNEL-PATH` in `testing/startup.fnl`)
2. Add `tests/startup-test.fnl` that calls `startup.run!`
3. Add `deps.fnl` and `tasks/run-tests` under `examples/<name>/`
4. Provide `main.fnl` and `main.lua` (required for auto-discovery)
5. Add `visual/` golden harness unless **visual-exempt** (`keep-going-right` only — use `shared/character/visual/` for the stick figure)

CI runs [`tests/example-coverage-test.fnl`](examples/shared/tests/example-coverage-test.fnl) for policy checks and [`tests/all-examples-startup-test.fnl`](examples/shared/tests/all-examples-startup-test.fnl) to smoke-test startup in every discovered example.

## Which examples use what

| Example | grid | love-ui | util | tick | audio | character |
|---|---|---|---|---|---|---|
| tic-tac-toe | ✓ | ✓ | ✓ | | |
| game-menu | | ✓ | ✓ | | ✓ |
| grid-chase | ✓ | ✓ | ✓ | ✓ | ✓ |
| snake | ✓ | ✓ | ✓ | ✓ | ✓ |
| keep-going-right | | ✓ | | | | ✓ |

New Love2D examples should import from here before copying helpers. ECS core stays in [`src/`](../../src/) — prefer `(require :io.github.emgrasmeder.lux.world)` for the world API in game code (same as `(. (require :io.github.emgrasmeder.lux) :world)`). Only game/example code lives here. The platformer example uses continuous physics and does not use `shared.grid` or `shared.tick`.

## Character preview (interactive)

Manual Love window at [`character/preview/`](examples/shared/character/preview/) to watch the shared stick figure and walk cycle. Use this when you want to see the character; use [`character/visual/`](examples/shared/character/visual/) for automated golden PNG tests; use [`keep-going-right`](../keep-going-right/) for the full platformer with the same renderer.

**Run (needs [Love 11+](https://love2d.org/) on PATH):**

```bash
cd examples/shared/character/preview
deps --lua-version 5.1 --no-prompt
love .
# or: ./tasks/run-preview
```

Hold **A/D** or arrow keys to walk; **Escape** quits.

## Character visual golden tests

Headless Love harness at [`character/visual/`](examples/shared/character/visual/) renders four isolated stick-figure poses and pixel-compares them to PNGs in [`character/visual/fixtures/`](examples/shared/character/visual/fixtures/). The window is hidden and the process exits after compare — not for manual viewing (see **Character preview** above).

**Run (needs [Love 11+](https://love2d.org/) on PATH):**

```bash
cd examples/shared/character/visual
deps --lua-version 5.1 --no-prompt
./tasks/run-visual-tests
```

**Refresh baselines** (use the podman CI image so goldens match Linux CI):

```bash
podman run --rm -v "$PWD:/work:Z" -w /work -e UPDATE_VISUAL_FIXTURES=1 -e DEPS_NO_PROMPT=true \
  fnl-lux-ci:local bash -lc 'cd examples/shared/character/visual && deps --lua-version 5.1 --no-prompt && ./tasks/run-visual-tests'
```

(`./scripts/ci-test.sh` runs these automatically after the Fennel test suite.)

