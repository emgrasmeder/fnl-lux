(local c (require :constants))
(local love-ui (require :shared.love-ui))
(local physics-world (require :physics-world))

(fn render-ground []
  (love.graphics.setColor 0.25 0.22 0.2 1)
  (love.graphics.rectangle :fill 0 c.GROUND-Y c.WINDOW-W (- c.WINDOW-H c.GROUND-Y))
  (love.graphics.setColor 0.35 0.32 0.28 1)
  (love.graphics.line 0 c.GROUND-Y c.WINDOW-W c.GROUND-Y))

(fn render-crane-mast []
  (love.graphics.setColor 0.4 0.4 0.44 1)
  (love.graphics.rectangle :fill (- c.BASE-X 10) c.BASE-Y 20 (- c.GROUND-Y c.BASE-Y)))

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
    (let [body (. rec :body)]
      (when (and body (. body :getWorldPoints))
        (let [half c.brick-half
              r (. rec :r)
              g (. rec :g)
              b (. rec :b)]
          (love.graphics.setColor r g b 1)
          (love.graphics.polygon :fill
                                 ((. body :getWorldPoints) body
                                  (- half) (- half)
                                  half (- half)
                                  half half
                                  (- half) half))
          (when (. rec :target?)
            (love.graphics.setColor 0.95 0.85 0.1 1)
            (love.graphics.setLineWidth 2)
            (love.graphics.polygon :line
                                   ((. body :getWorldPoints) body
                                    (- half) (- half)
                                    half (- half)
                                    half half
                                    (- half) half))
            (love.graphics.setLineWidth 1)))))))

(fn format-score [n]
  (string.format "%.0f" n))

(fn render-playing-hud [state score pw]
  (love.graphics.setColor 0.9 0.9 0.92 1)
  (love.graphics.print (string.format "Round %d/%d  Score: %s"
                                        (. state :round)
                                        c.TOTAL-ROUNDS
                                        (format-score (. score :total-score)))
                         12 12)
  (love.graphics.print (string.format "Chain: %.0f  Wheel: length  Enter: next round"
                                      (. pw :chain-len))
                       12 28)
  (love.graphics.print "Destroy the red building (yellow outline). R = restart run." 12 44))

(fn render-summary-hud [score]
  (love.graphics.setColor 0.95 0.95 0.98 1)
  (love.graphics.print "Run complete" 12 12)
  (love.graphics.print (string.format "Total score: %s" (format-score (. score :total-score))) 12 32)
  (var y 52)
  (each [i bonus (ipairs (. score :round-scores))]
    (love.graphics.print (string.format "Round %d bonus: %s" i (format-score bonus)) 12 y)
    (set y (+ y 16)))
  (love.graphics.print "Enter or R: new run" 12 (+ y 12)))

(fn render-hud [state game]
  (let [score (. game :score)
        pw (. game :physics)]
    (if (= (. state :phase) :summary)
        (render-summary-hud score)
        (render-playing-hud state score pw))))

(fn render [game state]
  (love-ui.clear-background)
  (render-ground)
  (let [pw (. game :physics)]
    (render-bricks pw)
    (render-crane-mast)
    (render-crane-base)
    (render-arm (. pw :arm))
    (render-cable pw)
    (render-ball (. pw :ball)))
  (render-hud state game))

{:render render}
