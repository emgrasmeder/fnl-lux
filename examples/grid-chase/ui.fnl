(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))

(fn entity-components [world entity-id]
  (get-table-by-id world entity-id))

(fn render-grid []
  (let [ox world-mod.BOARD-OX
        oy world-mod.BOARD-OY
        size world-mod.CELL-SIZE
        board-w (* world-mod.GRID-W size)
        board-h (* world-mod.GRID-H size)]
    (love.graphics.setColor 0.9 0.9 0.95 1)
    (for [col 0 world-mod.GRID-W]
      (love.graphics.line (+ ox (* col size)) oy (+ ox (* col size)) (+ oy board-h)))
    (for [row 0 world-mod.GRID-H]
      (love.graphics.line ox (+ oy (* row size)) (+ ox board-w) (+ oy (* row size))))))

(fn render-walls [game]
  (let [world game.world
        cell-at game.cell-at]
    (love.graphics.setColor 0.35 0.35 0.45 1)
    (for [row 1 game.grid-h]
      (for [col 1 game.grid-w]
        (let [entity-id (. cell-at (world-mod.cell-key row col))
              components (entity-components world entity-id)]
          (when (and components (= (. components.terrain 1) :wall))
            (let [[x y w h] components.cell-bounds]
              (love.graphics.rectangle "fill" x y w h))))))))

(fn render-label [x y w h label]
  (let [font (love.graphics.getFont)
        text-width (font:getWidth label)
        text-height (font:getHeight)]
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print label
                         (+ x (/ (- w text-width) 2))
                         (+ y (/ (- h text-height) 2)))))

(fn render-actors [game]
  (let [world game.world
        monster-pos (systems.get-actor-position game game.monster-id)
        goal-pos (systems.get-actor-position game game.goal-id)
        monster-cell (. game.cell-at (world-mod.cell-key (. monster-pos :row) (. monster-pos :col)))
        goal-cell (. game.cell-at (world-mod.cell-key (. goal-pos :row) (. goal-pos :col)))
        monster-bounds (entity-components world monster-cell)
        goal-bounds (entity-components world goal-cell)]
    (when monster-bounds
      (let [[x y w h] monster-bounds.cell-bounds]
        (render-label x y w h "X")))
    (when goal-bounds
      (let [[x y w h] goal-bounds.cell-bounds]
        (render-label x y w h "O")))))

(fn render [game]
  (love.graphics.clear 0.08 0.08 0.1 1)
  (render-walls game)
  (render-grid)
  (render-actors game))

{:render render}
