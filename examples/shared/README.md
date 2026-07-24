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
| `love-ui.fnl`           | `:shared.love-ui`           | Love2D drawing primitives (background, line grid, filled rects, centered text, overlays, `render-stick-figure`) |
| `audio.fnl`             | `:shared.audio`             | Procedural tone generation (`make-tone`, `make-lazy-player`)                                                    |
| `util.fnl`              | `:shared.util`              | `shuffle!`, `positions-equal?`, `point-in-rect?`                                                                |
| `tick.fnl`              | `:shared.tick`              | Fixed-interval game step timer (`step-on-interval`)                                                             |
| `testing/love-mock.fnl` | `:shared.testing.love-mock` | Headless Love2D stub for CI                                                                                     |
| `testing/discover.fnl`  | `:shared.testing.discover`  | Discover Love2D example dirs; run per-example shell commands                                                    |
| `testing/startup.fnl`   | `:shared.testing.startup`   | Smoke-test `love.load` / `love.update` / `love.draw` using production fennel paths                              |

## New Love2D example checklist

1. Add `../?.fnl` to fennel `path` in `main.lua` (match `PRODUCTION-FENNEL-PATH` in `testing/startup.fnl`)
2. Add `tests/startup-test.fnl` that calls `startup.run!`
3. Add `deps.fnl` and `tasks/run-tests` under `examples/<name>/`
4. Provide `main.fnl` and `main.lua` (required for auto-discovery)

CI runs [`tests/example-coverage-test.fnl`](examples/shared/tests/example-coverage-test.fnl) for policy checks and [`tests/all-examples-startup-test.fnl`](examples/shared/tests/all-examples-startup-test.fnl) to smoke-test startup in every discovered example.

## Which examples use what

| Example | grid | love-ui | util | tick | audio |
|---|---|---|---|---|---|
| tic-tac-toe | ✓ | ✓ | ✓ | | |
| game-menu | | ✓ | ✓ | | ✓ |
| grid-chase | ✓ | ✓ | ✓ | ✓ | ✓ |
| snake | ✓ | ✓ | ✓ | ✓ | ✓ |
| keep-going-right | | ✓ | | | |

New Love2D examples should import from here before copying helpers. ECS core stays in `src/` — only game/example code lives here. The platformer example uses continuous physics and does not use `shared.grid` or `shared.tick`.
