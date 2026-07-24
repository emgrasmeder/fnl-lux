(local c (require :constants))
(local love-ui (require :shared.love-ui))
(local physics-world (require :physics-world))
(fn render-ground []
  (love.graphics.setColor 0.25 0.22 0.2 1)
  (love.graphics.rectangle :fill 0 c.GROUND-Y c.WINDOW-W (- c.WINDOW-H c.GROUND-Y))
  (love.graphics.setColor 0.35 0.32 0.28 1)
  (love.graphics.line 0 c.GROUND-Y c.WINDOW-W c.GROUND-Y))

(fn render-crane-base []
  (love.graphics.setColor 0.45 0.45 0.5 1)
  (love.graphics.circle :fill c.BASE-X c.BASE-Y c.BASE-R))

(fn render-arm [arm-body]
  (when (and arm-body (. arm-body :getWorldPoints))
    (love.graphics.setColor 0.55 0.5 0.45 1)
    (love.graphics.polygon :fill
                           ((. arm-body :getWorldPoints) arm-body
                            (- (/ c.ARM-LEN 2)) (- (/ c.ARM-THICK 2))
                            (- (/ c.ARM-LEN 2)) (/ c.ARM-THICK 2)
                            (/ c.ARM-LEN 2) (/ c.ARM-THICK 2)
                            (/ c.ARM-LEN 2) (- (/ c.ARM-THICK 2))))))

(fn render-cable [pw]
  (let [[tx ty] (physics-world.arm-tip-xy (. pw :arm))
        [bx by] (physics-world.body-xy (. pw :ball))]
    (love.graphics.setColor 0.2 0.2 0.2 1)
    (love.graphics.line tx ty bx by)))

(fn render-ball [ball-body]
  (when ball-body
    (let [[x y] (physics-world.body-xy ball-body)]
      (love.graphics.setColor 0.35 0.35 0.38 1)
      (love.graphics.circle :fill x y c.BALL-R))))

(fn render-bricks [pw]
  (each [_ rec (ipairs (. pw :brick-records))]
    (let [body (. rec :body)
          hue (/ (. rec :hue) 360)]
      (when (and body (. body :getWorldPoints))
        (let [half c.brick-half]
          (love.graphics.setColor (+ 0.35 (* hue 0.3)) 0.28 0.22 1)
          (love.graphics.polygon :fill
                                 ((. body :getWorldPoints) body
                                  (- half) (- half)
                                  half (- half)
                                  half half
                                  (- half) half)))))))

(fn render-hud []
  (love.graphics.setColor 0.9 0.9 0.92 1)
  (love.graphics.print "Move mouse — wreck buildings. R = reset." 12 12))

(fn render [game _state]
  (love-ui.clear-background)
  (render-ground)
  (let [pw (. game :physics)]
    (render-bricks pw)
    (render-crane-base)
    (render-arm (. pw :arm))
    (render-cable pw)
    (render-ball (. pw :ball)))
  (render-hud))

{:render render}
