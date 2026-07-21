# Tic-Tac-Toe Love2D Example

A two-player tic-tac-toe game in Love2D, built on [Lux](https://github.com/emgrasmeder/fnl-lux).

The board is modeled as nine ECS cell entities, each with `:position`, `:mark`, and `:cell-bounds` components.

## Prerequisites

- [Love2D 11+](https://love2d.org/)
- [deps.fnl](https://gitlab.com/andreyorst/deps.fnl)
- [Fennel](https://fennel-lang.org/) (installed automatically as a Lua rock via `deps`)

## Setup

```bash
cd examples/tic-tac-toe
deps
deps --lua-version 5.1 --no-prompt
```

Love2D uses Lua 5.1; the second command installs the Fennel rock for that runtime.

Run `deps --fennel-ls` to regenerate `flsproject.fnl` for editor tooling.

## Run

```bash
cd examples/tic-tac-toe
love .
```

## Play

- **Mouse** — click an empty cell to play
- X and O alternate; the first player is chosen at random
- When someone wins or the board is full, press **R** to start a new game

## Testing

```bash
cd examples/tic-tac-toe
deps --profiles dev tasks/run-tests
```

This example loads Lux from the parent repo checkout (`../../src`) via `deps.fnl` paths and `main.lua`.
