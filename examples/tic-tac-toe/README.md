# Tic-Tac-Toe CLI Example

A two-player tic-tac-toe game in the terminal, built on [Lux](https://github.com/emgrasmeder/fnl-lux).

The board is modeled as nine ECS cell entities, each with `:position` and `:mark` components.

## Run

```bash
cd examples/tic-tac-toe
deps
deps main.fnl
```

Requires [deps.fnl](https://gitlab.com/andreyorst/deps.fnl) and [Fennel](https://fennel-lang.org/). Run `deps --fennel-ls` to regenerate `flsproject.fnl` for editor tooling.

## Play

- Coordinates are `1,1` (top-left) through `3,3` (bottom-right).
- Enter a move as `1,2` or `1 2`.
- X and O alternate; the first player is chosen at random.

## Testing

```bash
cd examples/tic-tac-toe
deps --profiles dev tasks/run-tests
```

This example loads Lux from the parent repo checkout (`../../src`) via `deps.fnl` paths.
