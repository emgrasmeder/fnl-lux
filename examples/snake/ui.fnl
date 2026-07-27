(local world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. world :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))
(local layout (require :layout))
(local love-ui (require :shared.love-ui))

(fn render-walls [game]
  (let [world game.world
        cell-at game.cell-at]
    (love.graphics.setColor 0.35 0.35 0.45 1)
    (for [row 1 game.grid-h]
      (for [col 1 game.grid-w]
        (when (world-mod.border? row col)
          (let [entity-id (. cell-at (world-mod.cell-key row col))
                components (get-table-by-id world entity-id)]
            (when components
              (let [[x y w h] components.cell-bounds]
                (love-ui.fill-rect "fill" x y w h)))))))))

(fn render-snake [body]
  (love.graphics.setColor 0.25 0.45 0.3 1)
  (love-ui.fill-rects (layout.segment-rects body)))

(fn render-food [food-pos]
  (let [rect (layout.food-rect food-pos)]
    (when rect
      (love.graphics.setColor 1 1 1 1)
      (love-ui.fill-rects [rect]))))

(fn render-score [state]
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print (.. "Score: " (systems.score state)) 8 8))

(fn render [game state]
  (love-ui.clear-background)
  (render-walls game)
  (love-ui.render-line-grid world-mod.BOARD-OX world-mod.BOARD-OY
                            world-mod.GRID-W world-mod.GRID-H world-mod.CELL-SIZE)
  (render-food (systems.get-food-position game))
  (render-snake state.body)
  (render-score state)
  (let [text (systems.overlay-text state)]
    (when text (love-ui.render-message-overlay text))))

{:render render}
