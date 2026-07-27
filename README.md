# Lux
A **L**öve **ECS**

🚧This is mostly a personal playground for now 👷‍♀️

## Installation

Add this to your `deps.fnl` file:
```fennel
 :deps {:com.github.emgrasmeder/lux.fnl
        {:type :git :sha "7191549e7d96bd0493e307e83c7c3f7be1bff2dd"
         :paths {:fennel ["?.fnl"]}}}
```
and then run `~/src/gitlab.com/andreyorst/deps.fnl/deps` from the root of your project. Now you have a `.deps/` folder in your repository. 
You can access functions from Lux like:
```fennel
(local deps (require :deps))
(. deps.component-store/create <... your args here>)
```

There's probably a better way but that's as much as I've figured out from deps.fnl so far. 

## Love2d ECS

I just think ECS is a neat pattern

### Entities

I guess these are the atoms of your game. The simplest primitive?

### Components

data to model your entities

### Systems

acts on entities given according to certain conditions. i really gotta learn how these things work before i try to explain it to anyone else


## Use

The entry point to the ECS is `world/create`. You can pass it an argument like `{:componentStoreName {:arg1 :arg2}}`... See the `examples/` directory for more depth

## Testing

### Running tests in Podman

see [`Containerfile`](Containerfile)

- **macOS:** Install [Podman Desktop](https://podman-desktop.io/) or `brew install podman`, then run `podman machine init && podman machine start`.
- **Linux:** Install the `podman` package from your distribution.

**Run all tests**

```bash
./scripts/ci-test.sh
```

The first run builds the `fnl-lux-ci:local` image

### Running tests natively

If you've installed the deps.fnl binary, you can run
```
deps --profiles dev tasks/run-tests
```
to run the Lux library tests and **all** Love2D examples under [`examples/`](examples/) (discovered automatically). To run only a subset, pass test names as arguments (see fennel-test docs). Add new root tests to the list in the `run-tests` file; example tests live under each example's `tests/` directory.

Root [`all-examples-startup-test`](examples/shared/tests/all-examples-startup-test.fnl) runs `startup-test` in every discovered example (folders with `main.fnl` and `main.lua`, excluding `shared`). Root [`tasks/run-tests`](tasks/run-tests) then runs each example.

Every Love2D example must include `tests/startup-test.fnl`, which smoke-tests `love.load`, optional `love.update`, and `love.draw` using a headless Love mock from [`examples/shared/testing/`](examples/shared/testing/) (no Love2D binary required for that step). **`./scripts/ci-test.sh`** runs fennel-test, then Love golden-image tests via [`examples/shared/testing/run-all-visual-tests.sh`](examples/shared/testing/run-all-visual-tests.sh) (character stick figure plus each example’s `visual/` harness; Love + xvfb in CI). Committed PNG fixtures should be captured in the **Linux podman CI image** when possible; refresh with `UPDATE_VISUAL_FIXTURES=1` (see [`examples/shared/README.md`](examples/shared/README.md)).

When adding a new Love2D example:

1. Include `../?.fnl` in `main.lua` fennel `path` (keep in sync with `PRODUCTION-FENNEL-PATH` in [`examples/shared/testing/startup.fnl`](examples/shared/testing/startup.fnl))
2. Add `tests/startup-test.fnl` calling `(require :shared.testing.startup)` / `startup.run!`
3. Add `deps.fnl`, `tasks/run-tests`, and the usual `main.fnl` / `main.lua` / `conf.lua` under `examples/<name>/`
4. Add `visual/` golden tests (see shared README) unless the example is on the visual-exempt list (`keep-going-right` only)

Discovery picks up the new folder automatically. Root [`example-coverage-test`](examples/shared/tests/example-coverage-test.fnl) enforces the startup and bootstrap checklist in CI.

## Examples

Shared Love2D helpers live in [`examples/shared/`](examples/shared/) (grid math, UI drawing, audio tones, timers, and headless startup tests). Individual games import subsets of those modules.

- [Tic-Tac-Toe Love2D](examples/tic-tac-toe/) — two-player tic-tac-toe using Lux ECS for the board
- [Game Menu](examples/game-menu/) — Love2D menu with Play (beep) and Exit buttons using Lux ECS
- [Grid Chase](examples/grid-chase/) — monster pathfinds to a moving goal on a wall-filled grid using A* and Lux ECS
- [Snake](examples/snake/) — classic Snake with a controllable `:player` head entity, food, pause, and restart
- [Keep Going Right](examples/keep-going-right/) — endless side-scrolling platformer with capsule physics, procedural terrain panes, a Lux `:player` entity, and a shared line-art stick figure

##### Disclaimer
I don't know how to make games, how to code in fennel, or how to build an ECS. I'm gratefully forking this repository from Benaiah so that I can add documentation for my own reference, and edit things in an attempt to understand them better.
