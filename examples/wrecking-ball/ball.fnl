(local c (require :constants))
(local physics (require :physics))

(fn initial-ball []
  {:x c.BASE-X
   :y (- c.GROUND-Y c.CHAIN-LEN c.BALL-R 4)
   :vx 0
   :vy 0})

(fn step-ball [ball dt]
  (physics.integrate-body ball dt false)
  (let [contact (physics.circle-ground-contact (. ball :x) (. ball :y) c.BALL-R (. ball :vy))]
    (when contact.hit
      (tset ball :y (- c.GROUND-Y c.BALL-R))
      (when (> (. ball :vy) 0)
        (tset ball :vy (* (- (. ball :vy)) c.GROUND-FRICTION)))
      (tset ball :vx (* (. ball :vx) c.GROUND-FRICTION)))
    ball))

{:initial-ball initial-ball
 :step-ball step-ball}
