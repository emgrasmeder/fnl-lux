(local c (require :constants))
(local love-ui (require :shared.love-ui))
(local physics (require :physics))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(fn render-ground []
  (love.graphics.setColor 0.25 0.22 0.2 1)
  (love.graphics.rectangle :fill 0 c.GROUND-Y c.WINDOW-W (- c.WINDOW-H c.GROUND-Y))
  (love.graphics.setColor 0.35 0.32 0.28 1)
  (love.graphics.line 0 c.GROUND-Y c.WINDOW-W c.GROUND-Y))

(fn render-crane [crane]
  (love.graphics.setColor 0.45 0.45 0.5 1)
  (love.graphics.circle :fill c.BASE-X c.BASE-Y c.BASE-R)
  (let [dx (- (. crane :tip-x) c.BASE-X)
        dy (- (. crane :tip-y) c.BASE-Y)
        len (physics.len dx dy)
        nx (if (< len 1e-9) 0 (/ dx len))
        ny (if (< len 1e-9) -1 (/ dy len))
        px (* (- ny) (/ c.ARM-THICK 2))
        py (* nx (/ c.ARM-THICK 2))]
    (love.graphics.setColor 0.55 0.5 0.45 1)
    (love.graphics.polygon :fill
                           c.BASE-X c.BASE-Y
                           (+ c.BASE-X px) (+ c.BASE-Y py)
                           (+ (. crane :tip-x) px) (+ (. crane :tip-y) py)
                           (. crane :tip-x) (. crane :tip-y))))

(fn render-cable [crane ball]
  (love.graphics.setColor 0.2 0.2 0.2 1)
  (love.graphics.line (. crane :tip-x) (. crane :tip-y) (. ball :x) (. ball :y)))

(fn render-ball [ball]
  (love.graphics.setColor 0.35 0.35 0.38 1)
  (love.graphics.circle :fill (. ball :x) (. ball :y) c.BALL-R))

(fn render-bricks [game]
  (each [_ id (ipairs (. game :brick-ids))]
    (let [comp (get-table-by-id (. game :world) id)]
      (when comp
        (let [x (. comp.position 1)
              y (. comp.position 2)
              angle (. comp.rotation 1)
              hue (/ (. comp.brick-hue 1) 360)
              corners (physics.obb-corners x y angle c.brick-half)]
          (love.graphics.setColor (+ 0.35 (* hue 0.3)) 0.28 0.22 1)
          (love.graphics.polygon :fill
                                 (. (. corners 1) 1) (. (. corners 1) 2)
                                 (. (. corners 2) 1) (. (. corners 2) 2)
                                 (. (. corners 3) 1) (. (. corners 3) 2)
                                 (. (. corners 4) 1) (. (. corners 4) 2)))))))

(fn render-hud []
  (love.graphics.setColor 0.9 0.9 0.92 1)
  (love.graphics.print "Move mouse — wreck buildings. R = reset." 12 12))

(fn render [sim-game sim]
  (love-ui.clear-background)
  (render-ground)
  (render-bricks sim-game)
  (render-crane (. sim :crane))
  (render-cable (. sim :crane) (. sim :ball))
  (render-ball (. sim :ball))
  (render-hud))

{:render render}
