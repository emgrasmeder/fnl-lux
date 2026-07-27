(local world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. world :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))
(local love-ui (require :shared.love-ui))

(fn render-mark [x y w h mark]
  (when (or (= mark :X) (= mark :O))
    (love.graphics.setColor 1 1 1 1)
    (love-ui.print-centered-in-rect (systems.player-label mark) x y w h)))

(fn render-board [game]
  (let [world game.world
        cell-at game.cell-at]
    (for [row 1 3]
      (for [col 1 3]
        (let [entity-id (. cell-at (world-mod.cell-key row col))
              components (get-table-by-id world entity-id)]
          (when components
            (let [[x y w h] components.cell-bounds
                  mark (. components.mark 1)]
              (render-mark x y w h mark))))))))

(fn render [game state]
  (love-ui.clear-background)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print (systems.status-text state) 20 20)
  (love-ui.render-tic-tac-toe-grid world-mod.board-ox world-mod.board-oy world-mod.cell-size)
  (render-board game)
  (when (= state.phase :ended)
    (love.graphics.print "Press R to play again" 20 440)))

{:render render}
