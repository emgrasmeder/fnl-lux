# Grid Chase Love2D Example

A monster (X) chases a moving goal (O) on a grid with walls, built on [Lux](https://github.com/emgrasmeder/fnl-lux).

The grid is modeled as ECS cell entities with `:position`, `:terrain`, and `:cell-bounds` components. The monster and goal are separate actor entities. Movement uses A* pathfinding with one step per second.

## Prerequisites

- [Love2D 11+](https://love2d.org/)
- [deps.fnl](https://gitlab.com/andreyorst/deps.fnl)
- [Fennel](https://fennel-lang.org/) (installed automatically as a Lua rock via `deps`)

## Setup

```bash
cd examples/grid-chase
deps
deps --lua-version 5.1 --no-prompt
```

Love2D uses Lua 5.1; the second command installs the Fennel rock for that runtime.

Run `deps --fennel-ls` to regenerate `flsproject.fnl` for editor tooling.

## Run

```bash
cd examples/grid-chase
love .
```

## Play

- The monster (X) pathfinds toward the goal (O) automatically
- One step per second
- When the monster reaches the goal, a sound plays and the goal moves to a new random empty cell
- **Escape** — quit

## Testing

```bash
cd examples/grid-chase
deps --profiles dev tasks/run-tests
```

From the repo root, grid-chase tests also run as part of `deps --profiles dev tasks/run-tests`.

This example loads Lux from the parent repo checkout (`../../src`) via `deps.fnl` paths and `main.lua`.
