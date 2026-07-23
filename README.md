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
to run the Lux library tests and the [tic-tac-toe](examples/tic-tac-toe/), [game-menu](examples/game-menu/), [grid-chase](examples/grid-chase/), [snake](examples/snake/), and [keep-going-right](examples/keep-going-right/) example tests. To run only a subset, pass test names as arguments (see fennel-test docs). Add new root tests to the list in the `run-tests` file; example tests live under each example's `tests/` directory.

Every Love2D example must include `tests/startup-test.fnl`, which smoke-tests `love.load`, optional `love.update`, and `love.draw` using a headless Love mock from [`examples/shared/testing/`](examples/shared/testing/) (no Love2D binary required in CI). Startup tests bootstrap Fennel with the same **production** paths as each example's `main.lua` (including `../?.fnl` for shared modules), not the deps dev profile alone.

When adding a new Love2D example:

1. Include `../?.fnl` in `main.lua` fennel `path` (keep in sync with `PRODUCTION-FENNEL-PATH` in [`examples/shared/testing/startup.fnl`](examples/shared/testing/startup.fnl))
2. Add `tests/startup-test.fnl` calling `(require :shared.testing.startup)` / `startup.run!`
3. Register the example in the `examples` list in root [`tasks/run-tests`](tasks/run-tests)

Root [`example-coverage-test`](examples/shared/tests/example-coverage-test.fnl) enforces this checklist in CI.

## Examples

Shared Love2D helpers live in [`examples/shared/`](examples/shared/) (grid math, UI drawing, audio tones, timers, and headless startup tests). Individual games import subsets of those modules.

- [Tic-Tac-Toe Love2D](examples/tic-tac-toe/) — two-player tic-tac-toe using Lux ECS for the board
- [Game Menu](examples/game-menu/) — Love2D menu with Play (beep) and Exit buttons using Lux ECS
- [Grid Chase](examples/grid-chase/) — monster pathfinds to a moving goal on a wall-filled grid using A* and Lux ECS
- [Snake](examples/snake/) — classic Snake with a controllable `:player` head entity, food, pause, and restart
- [Keep Going Right](examples/keep-going-right/) — endless side-scrolling platformer with capsule physics, procedural terrain panes, and a Lux `:player` entity

##### Disclaimer
I don't know how to make games, how to code in fennel, or how to build an ECS. I'm gratefully forking this repository from Benaiah so that I can add documentation for my own reference, and edit things in an attempt to understand them better.
