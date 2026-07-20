# Game Menu Example

A minimal Love2D menu with **Play** and **Exit** buttons, built on [Lux](https://github.com/emgrasmeder/fnl-lux) ECS.

Each button is an entity with `:button`, `:label`, and `:action` components. Input and rendering are handled by separate systems.

## Prerequisites

- [Love2D 11+](https://love2d.org/)
- [deps.fnl](https://gitlab.com/andreyorst/deps.fnl)
- [Fennel](https://fennel-lang.org/) (installed automatically as a Lua rock via `deps`)

## Setup

```bash
cd examples/game-menu
deps
deps --lua-version 5.1 --no-prompt
```

Love2D uses Lua 5.1; the second command installs the Fennel rock for that runtime.

Run `deps --fennel-ls` to regenerate `flsproject.fnl` for editor tooling.

## Run

```bash
cd examples/game-menu
love .
```

## Controls

- **Mouse** — click a button
- **Up / Down** — change focused button
- **Enter / Space** — activate focused button
- **Escape** — exit

**Play** plays a short procedural beep and stays on the menu. **Exit** closes the application.

## Testing

```bash
cd examples/game-menu
deps --profiles dev tasks/run-tests
```

From the repo root, game-menu tests also run as part of `deps --profiles dev tasks/run-tests`.

This example loads Lux from the parent repo checkout (`../../src`) via `deps.fnl` paths and `main.lua`.
