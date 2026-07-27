(local c (require :constants))

(local tau (* math.pi 2))

(fn normalize-angle [a]
  (var x a)
  (while (< x (- math.pi)) (set x (+ x tau)))
  (while (>= x math.pi) (set x (- x tau)))
  x)

(fn angle-diff [from to]
  (normalize-angle (- to from)))

(fn turn-toward [current target max-delta]
  (let [diff (angle-diff current target)]
    (if (> (math.abs diff) max-delta)
        (+ current (* (if (> diff 0) 1 -1) max-delta))
        target)))

(fn heading-to-velocity [heading speed]
  [(* speed (math.cos heading)) (* speed (math.sin heading))])

(fn integrate-alive [x y heading speed turn-rate desired-heading dt]
  (let [new-heading (turn-toward heading desired-heading (* turn-rate dt))
        [vx vy] (heading-to-velocity new-heading speed)
        new-x (+ x (* vx dt))
        new-y (+ y (* vy dt))]
    {:x new-x :y new-y :heading new-heading :vx vx :vy vy}))

(fn integrate-wreck [x y vx vy dt]
  (let [new-vy (+ vy (* c.GRAVITY dt))
        new-x (+ x (* vx dt))
        new-y (+ y (* new-vy dt))]
    {:x new-x :y new-y :vx vx :vy new-vy}))

(fn dist [x1 y1 x2 y2]
  (let [dx (- x2 x1) dy (- y2 y1)]
    (math.sqrt (+ (* dx dx) (* dy dy)))))

(fn desired-heading-to [x y tx ty]
  (math.atan (- ty y) (- tx x)))

{:normalize-angle normalize-angle
 :angle-diff angle-diff
 :turn-toward turn-toward
 :heading-to-velocity heading-to-velocity
 :integrate-alive integrate-alive
 :integrate-wreck integrate-wreck
 :dist dist
 :desired-heading-to desired-heading-to}
