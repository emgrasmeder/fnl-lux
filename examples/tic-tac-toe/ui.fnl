(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))

(fn entity-components [world entity-id]
  (get-table-by-id world entity-id))

(fn render-grid []
  (let [ox world-mod.board-ox
        oy world-mod.board-oy
        size world-mod.cell-size
        board-size (* 3 size)]
    (love.graphics.setColor 0.9 0.9 0.95 1)
    (love.graphics.rectangle "line" ox oy board-size board-size)
    (for [i 1 2]
      (let [offset (* i size)]
        (love.graphics.line (+ ox offset) oy (+ ox offset) (+ oy board-size))
        (love.graphics.line ox (+ oy offset) (+ ox board-size) (+ oy offset))))))

(fn render-mark [x y w h mark]
  (when (or (= mark :X) (= mark :O))
    (let [label (systems.player-label mark)
          font (love.graphics.getFont)
          text-width (font:getWidth label)
          text-height (font:getHeight)]
      (love.graphics.setColor 1 1 1 1)
      (love.graphics.print label
                           (+ x (/ (- w text-width) 2))
                           (+ y (/ (- h text-height) 2))))))

(fn render-board [game]
  (let [world game.world
        cell-at game.cell-at]
    (for [row 1 3]
      (for [col 1 3]
        (let [entity-id (. cell-at (world-mod.cell-key row col))
              components (entity-components world entity-id)]
          (when components
            (let [[x y w h] components.cell-bounds
                  mark (. components.mark 1)]
              (render-mark x y w h mark))))))))

(fn render [game state]
  (love.graphics.clear 0.08 0.08 0.1 1)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print (systems.status-text state) 20 20)
  (render-grid)
  (render-board game)
  (when (= state.phase :ended)
    (love.graphics.print "Press R to play again" 20 440)))

{:render render}
