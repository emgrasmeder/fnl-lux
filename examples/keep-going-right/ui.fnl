(local c (require :constants))
(local love-ui (require :shared.love-ui))
(local character-render (require :shared.character.render))
(local walk (require :shared.character.walk))
(local world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. world :get-table-by-id))

(fn render-terrain [game cam-x]
  (love.graphics.setColor 0.9 0.9 0.95 1)
  (each [_ pane (pairs game.cam-state.panes)]
    (when pane
      (each [_ seg (ipairs pane.segments)]
        (love.graphics.line (- seg.x1 cam-x) seg.y1
                            (- seg.x2 cam-x) seg.y2)))))

(fn render-player [game state cam-x]
  (let [components (get-table-by-id game.world game.player-id)]
    (when (and components state.walk)
      (let [center-x (- (. components.position 1) cam-x)
            center-y (. components.position 2)
            feet-y (+ center-y (/ c.CAPSULE_H 2))
            vx (. components.velocity 1)
            move-sign (if (> (math.abs vx) c.WALK_VX_EPSILON)
                          (walk.sign vx)
                          (. state.walk :last-sign))
            phase (. state.walk :phase)]
        (love.graphics.setColor 1 1 1 1)
        (character-render.render-stick-figure center-x feet-y c.CAPSULE_H phase move-sign)))))

(fn render [game state]
  (love-ui.clear-background)
  (let [cam-x game.cam-state.camera-x]
    (render-terrain game cam-x)
    (render-player game state cam-x)))

{:render render}
