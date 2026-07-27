(local c (require :constants))
(local love-ui (require :shared.love-ui))
(local combat (require :combat))
(local world-mod (require :world))

(fn team-color [team]
  (case team
    :red [0.85 0.2 0.2]
    :green [0.2 0.75 0.35]
    _ [0.55 0.55 0.58]))

(fn render-sky []
  (love.graphics.setColor 0.45 0.65 0.9 1)
  (love.graphics.rectangle :fill 0 0 c.WINDOW-W c.GROUND-Y)
  (love.graphics.setColor 0.55 0.75 0.95 0.35)
  (love.graphics.rectangle :fill 0 40 c.WINDOW-W 120))

(fn render-ground []
  (love.graphics.setColor 0.28 0.32 0.22 1)
  (love.graphics.rectangle :fill 0 c.GROUND-Y c.WINDOW-W (- c.WINDOW-H c.GROUND-Y))
  (love.graphics.setColor 0.35 0.38 0.28 1)
  (love.graphics.line 0 c.GROUND-Y c.WINDOW-W c.GROUND-Y))

(fn render-building [w id]
  (let [comps (combat.get-table-by-id w id)]
    (when (and comps (> (. comps.hp 1) 0))
      (let [[x y] comps.position
            hp (. comps.hp 1)
            alpha (math.min 1 (/ hp c.MAX-HP))]
        (love.graphics.setColor 0.5 0.45 0.4 alpha)
        (love.graphics.rectangle :fill (- x (/ c.BUILDING-W 2)) (- y (/ c.BUILDING-H 2))
                                  c.BUILDING-W c.BUILDING-H)
        (love.graphics.setColor 0.9 0.85 0.75 alpha)
        (love.graphics.rectangle :line (- x (/ c.BUILDING-W 2)) (- y (/ c.BUILDING-H 2))
                                   c.BUILDING-W c.BUILDING-H)))))

(fn render-turret [w turret-id]
  (let [comps (combat.get-table-by-id w turret-id)]
    (when comps
      (let [[x y] comps.position
            [_ aim] comps.turret-state]
        (love.graphics.setColor 0.35 0.38 0.42 1)
        (love.graphics.rectangle :fill (- x 14) (- y 28) 28 28)
        (love.graphics.setColor 0.25 0.28 0.32 1)
        (love.graphics.circle :fill x y 18)
        (love.graphics.setColor 0.5 0.52 0.55 1)
        (love.graphics.line x y
                            (+ x (* (math.cos aim) c.TURRET-BARREL-LEN))
                            (+ y (* (math.sin aim) c.TURRET-BARREL-LEN)))))))

(fn render-plane [comps]
  (let [[x y] comps.position
        heading (. comps.heading 1)
        [r g b] (team-color (. comps.team 1))
        len 18]
    (love.graphics.setColor r g b 1)
    (love.graphics.line x y
                        (+ x (* (math.cos heading) len))
                        (+ y (* (math.sin heading) len)))
    (love.graphics.polygon :fill
                           x y
                           (+ x (* (math.cos (+ heading 2.4)) 10))
                           (+ y (* (math.sin (+ heading 2.4)) 10))
                           (+ x (* (math.cos (- heading 2.4)) 10))
                           (+ y (* (math.sin (- heading 2.4)) 10)))))

(fn render-entities [game]
  (let [w (. game :world)]
    (each [_ bid (ipairs (. game :building-ids))]
      (render-building w bid))
    (each [_ pid (ipairs (combat.select-entities w [:actor :position :heading :team :hp :plane-ai]))]
      (let [comps (combat.get-table-by-id w pid)]
        (when (and comps (= (. comps.actor 1) :plane))
          (render-plane comps))))
    (render-turret w (. game :turret-id))
    (each [_ id (ipairs (combat.select-entities w [:actor :position :projectile-meta]))]
      (let [comps (combat.get-table-by-id w id)]
        (when comps
          (case (. comps.actor 1)
            :bullet (do (love.graphics.setColor 0.95 0.9 0.4 1)
                        (love.graphics.circle :fill (. comps.position 1) (. comps.position 2) c.BULLET-R))
            :missile (do (love.graphics.setColor 0.95 0.5 0.15 1)
                         (love.graphics.circle :fill (. comps.position 1) (. comps.position 2) c.MISSILE-R))
            _ nil))))))

(fn count-buildings-left [game]
  (var n 0)
  (let [w (. game :world)]
    (each [_ bid (ipairs (. game :building-ids))]
      (let [b (combat.get-table-by-id w bid)]
        (when (and b (> (. b.hp 1) 0))
          (set n (+ n 1))))))
  n)

(fn render-hud [state]
  (love.graphics.setColor 0.95 0.95 0.98 1)
  (love.graphics.print (string.format "Time: %.0fs" (math.max 0 (. state :time-left))) 12 12)
  (if (<= (. state :missile-cooldown) 0)
      (love.graphics.print "Missiles [1]: READY" 12 32)
      (love.graphics.print (string.format "Missiles [1]: %.0fs" (. state :missile-cooldown)) 12 32))
  (love.graphics.print "Press 1 to fire missile salvo at nearest reds." 12 52))

(fn render-summary [game state]
  (let [stats (. state :stats)
        left (count-buildings-left game)
        destroyed (- c.BUILDING-COUNT left)
        outcome (if (= (. state :outcome) :win) "VICTORY" "DEFEAT")]
    (love-ui.render-message-overlay "")
    (love.graphics.setColor 0 0 0 0.65)
    (love.graphics.rectangle :fill 200 120 880 480)
    (love.graphics.setColor 0.95 0.95 0.98 1)
    (love.graphics.printf outcome 200 140 880 :center)
    (love.graphics.printf (string.format "Reds shot down: %d" (. stats :reds-killed)) 240 200 800 :left)
    (love.graphics.printf (string.format "Buildings remaining: %d / %d (destroyed: %d)"
                                         left c.BUILDING-COUNT destroyed)
                          240 230 800 :left)
    (love.graphics.printf (string.format "Turret damage dealt: %d" (. stats :turret-damage)) 240 260 800 :left)
    (love.graphics.printf (string.format "Friendly plane damage dealt: %d" (. stats :friendly-damage)) 240 290 800 :left)
    (love.graphics.printf (string.format "Missiles fired: %d  hits: %d"
                                         (. stats :missiles-fired) (. stats :missile-hits))
                          240 320 800 :left)
    (love.graphics.printf "Press R or Enter to play again." 240 400 800 :center)))

(fn render [game state]
  (love-ui.clear-background)
  (render-sky)
  (render-ground)
  (render-entities game)
  (case (. state :phase)
    :summary (render-summary game state)
    _ (render-hud state)))

{:render render}
