(local c (require :constants))
(local love-ui (require :shared.love-ui))
(local physics (require :physics))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(fn render-terrain [game cam-x]
  (love.graphics.setColor 0.9 0.9 0.95 1)
  (each [_ pane (pairs game.cam-state.panes)]
    (when pane
      (each [_ seg (ipairs pane.segments)]
        (love.graphics.line (- seg.x1 cam-x) seg.y1
                            (- seg.x2 cam-x) seg.y2)))))

(fn render-player [game cam-x]
  (let [components (get-table-by-id game.world game.player-id)]
    (when components
      (let [x (- (. components.position 1) cam-x)
            y (. components.position 2)
            half (c.capsule-half-body)
            label-x (- x 6)
            label-y (- y half 6)
            w 12
            h 12]
        (love.graphics.setColor 1 1 1 1)
        (love-ui.print-centered-in-rect "X" label-x label-y w h)))))

(fn render [game _state]
  (love-ui.clear-background)
  (let [cam-x game.cam-state.camera-x]
    (render-terrain game cam-x)
    (render-player game cam-x)))

{:render render}
