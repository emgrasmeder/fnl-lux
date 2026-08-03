(local creep-draw (require :creep-draw))
(local bullet-draw (require :bullet-draw))
(local world-mod (require :world))

(local WIN-W 480)
(local WIN-H 280)
(local CREEP-Y 140)
(local TOWER-X 420)
(local TOWER-Y 140)
(local CREEP-SPEED-PX 60)
(local FIRE-INTERVAL 0.75)

(var creep-x 40)
(var walk-phase 0)
(var fire-cooldown 0)
(var bullets [])

(fn spawn-preview-bullet! []
  (let [dx (- creep-x TOWER-X)
        dy (- CREEP-Y TOWER-Y)
        dist (math.sqrt (+ (* dx dx) (* dy dy)))
        speed world-mod.BULLET-SPEED
        vx (if (> dist 0) (* speed (/ dx dist)) 0)
        vy (if (> dist 0) (* speed (/ dy dist)) 0)]
    (table.insert bullets {:x TOWER-X :y TOWER-Y :vx vx :vy vy})))

(fn love.load []
  (love.graphics.setDefaultFilter "nearest" "nearest")
  (love.window.setMode WIN-W WIN-H))

(fn love.update [dt]
  (set creep-x (+ creep-x (* CREEP-SPEED-PX dt)))
  (when (> creep-x (- WIN-W 60))
    (set creep-x 40))
  (set walk-phase (+ walk-phase (* dt world-mod.CREEP-BOB-RATE)))
  (set fire-cooldown (- fire-cooldown dt))
  (when (<= fire-cooldown 0)
    (spawn-preview-bullet!)
    (set fire-cooldown FIRE-INTERVAL))
  (var kept [])
  (each [_ b (ipairs bullets)]
    (tset b :x (+ b.x (* b.vx dt)))
    (tset b :y (+ b.y (* b.vy dt)))
    (when (and (>= b.x -20) (<= b.x (+ WIN-W 20))
               (>= b.y -20) (<= b.y (+ WIN-H 20)))
      (table.insert kept b)))
  (set bullets kept))

(fn love.draw []
  (love.graphics.clear 0.08 0.08 0.1 1)
  (love.graphics.setColor 0.55 0.35 0.2 1)
  (love.graphics.rectangle "fill" (- TOWER-X 10) (- TOWER-Y 10) 20 20)
  (creep-draw.render-creep! creep-x CREEP-Y world-mod.CREEP-DRAW-RADIUS walk-phase)
  (each [_ b (ipairs bullets)]
    (bullet-draw.render-bullet! b.x b.y world-mod.BULLET-RADIUS))
  (love.graphics.setColor 0.75 0.75 0.8 1)
  (love.graphics.print "Creep bob + blaster bullets preview   Esc: quit" 8 8))

(fn love.keypressed [key]
  (when (= key "escape")
    (love.event.quit)))
