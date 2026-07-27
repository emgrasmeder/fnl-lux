(local world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. world :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))
(local love-ui (require :shared.love-ui))

(fn render-walls [game]
  (let [world game.world
        cell-at game.cell-at]
    (love.graphics.setColor 0.35 0.35 0.45 1)
    (for [row 1 game.grid-h]
      (for [col 1 game.grid-w]
        (let [entity-id (. cell-at (world-mod.cell-key row col))
              components (get-table-by-id world entity-id)]
          (when (and components (= (. components.terrain 1) :wall))
            (let [[x y w h] components.cell-bounds]
              (love-ui.fill-rect "fill" x y w h))))))))

(fn render-actors [game]
  (let [world game.world
        monster-pos (systems.get-actor-position game game.monster-id)
        goal-pos (systems.get-actor-position game game.goal-id)
        monster-cell (. game.cell-at (world-mod.cell-key (. monster-pos :row) (. monster-pos :col)))
        goal-cell (. game.cell-at (world-mod.cell-key (. goal-pos :row) (. goal-pos :col)))
        monster-bounds (get-table-by-id world monster-cell)
        goal-bounds (get-table-by-id world goal-cell)]
    (love.graphics.setColor 1 1 1 1)
    (when monster-bounds
      (let [[x y w h] monster-bounds.cell-bounds]
        (love-ui.print-centered-in-rect "X" x y w h)))
    (when goal-bounds
      (let [[x y w h] goal-bounds.cell-bounds]
        (love-ui.print-centered-in-rect "O" x y w h)))))

(fn render [game]
  (love-ui.clear-background)
  (render-walls game)
  (love-ui.render-line-grid world-mod.BOARD-OX world-mod.BOARD-OY
                            world-mod.GRID-W world-mod.GRID-H world-mod.CELL-SIZE)
  (render-actors game))

{:render render}
