(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))
(local layout (require :layout))

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
                (love.graphics.rectangle "fill" x y w h)))))))))

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

(fn render-snake [body]
  (love.graphics.setColor 0.25 0.45 0.3 1)
  (each [_ [x y w h] (ipairs (layout.segment-rects body))]
    (love.graphics.rectangle "fill" x y w h)))

(fn render-food [food-pos]
  (let [rect (layout.food-rect food-pos)]
    (when rect
      (let [[x y w h] rect]
        (love.graphics.setColor 1 1 1 1)
        (love.graphics.rectangle "fill" x y w h)))))

(fn render-score [state]
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print (.. "Score: " (systems.score state)) 8 8))

(fn render-overlay [state]
  (let [text (systems.overlay-text state)]
    (when text
      (let [font (love.graphics.getFont)
            text-width (font:getWidth text)
            text-height (font:getHeight)
            screen-w (love.graphics.getWidth)
            screen-h (love.graphics.getHeight)]
        (love.graphics.setColor 0 0 0 0.5)
        (love.graphics.rectangle "fill" 0 0 screen-w screen-h)
        (love.graphics.setColor 1 1 1 1)
        (love.graphics.print text
                             (/ (- screen-w text-width) 2)
                             (/ (- screen-h text-height) 2))))))

(fn render [game state]
  (love.graphics.clear 0.08 0.08 0.1 1)
  (render-walls game)
  (render-grid)
  (render-food (systems.get-food-position game))
  (render-snake state.body)
  (render-score state)
  (render-overlay state))

{:render render}
