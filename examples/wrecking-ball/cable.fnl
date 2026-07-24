(local c (require :constants))
(local physics (require :physics))
(local crane-mod (require :crane))

(fn cable-state [tip-x tip-y ball-x ball-y]
  (let [dx (- ball-x tip-x)
        dy (- ball-y tip-y)
        dist (physics.len dx dy)]
    {:dist dist
     :slack (<= dist c.CHAIN-LEN)
     :nx (if (< dist 1e-9) 0 (/ dx dist))
     :ny (if (< dist 1e-9) 1 (/ dy dist))}))

(fn step-cable [crane ball dt]
  (let [st (cable-state (. crane :tip-x) (. crane :tip-y) (. ball :x) (. ball :y))]
    (when (not (. st :slack))
      (let [nx (. st :nx)
            ny (. st :ny)
            overlap (- (. st :dist) c.CHAIN-LEN)
            rvx (- (. ball :vx) (. crane :tip-vx))
            rvy (- (. ball :vy) (. crane :tip-vy))
            vn (physics.dot rvx rvy nx ny)
            corr (* c.CABLE-STIFFNESS overlap dt)
            impulse (/ (+ corr (* (- vn) 0.5))
                       (+ (/ 1 c.BALL-MASS) (/ 1 c.TIP-MASS)))]
        (tset ball :vx (- (. ball :vx) (* impulse nx (/ 1 c.BALL-MASS))))
        (tset ball :vy (- (. ball :vy) (* impulse ny (/ 1 c.BALL-MASS))))
        (crane-mod.apply-tip-impulse crane (- nx) (- ny) (* impulse (/ 1 c.TIP-MASS)))
        (tset ball :x (- (. ball :x) (* nx overlap 0.5)))
        (tset ball :y (- (. ball :y) (* ny overlap 0.5))))))
  {:crane crane :ball ball})

{:cable-state cable-state
 :step-cable step-cable}
