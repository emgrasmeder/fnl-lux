# Snake Love2D Example

Classic Snake built on [Lux](https://github.com/emgrasmeder/fnl-lux). The player head is a controllable `:player` entity; body segments are tracked in game state.

The grid uses ECS cell entities with `:position`, `:terrain`, and `:cell-bounds`. Border cells are walls. Food is a separate `:food` actor entity. The snake moves one cell per second.

## Prerequisites

- [Love2D 11+](https://love2d.org/)
- [deps.fnl](https://gitlab.com/andreyorst/deps.fnl)
- [Fennel](https://fennel-lang.org/) (installed automatically as a Lua rock via `deps`)

## Setup

```bash
cd examples/snake
deps
deps --lua-version 5.1 --no-prompt
```

Love2D uses Lua 5.1; the second command installs the Fennel rock for that runtime.

Run `deps --fennel-ls` to regenerate `flsproject.fnl` for editor tooling.

## Run

```bash
cd examples/snake
love .
```

## Play

- **Arrow keys / WASD** — change direction (180° reversals are ignored)
- One step per second while playing
- Eat the white square to grow; score equals snake length
- Hit a wall or yourself — game over
- **Escape** — pause / unpause
- **R** — restart (anytime)

## Testing

```bash
cd examples/snake
deps --profiles dev tasks/run-tests
```

From the repo root, snake tests also run as part of `deps --profiles dev tasks/run-tests`.

This example loads Lux from the parent repo checkout (`../../src`) via `deps.fnl` paths and `main.lua`.
