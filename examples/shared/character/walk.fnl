(fn sign [x]
  (if (> x 0) 1 (if (< x 0) -1 0)))

(fn initial-walk-state []
  {:phase 0
   :dist-acc 0
   :last-sign 1})

(fn foot-positions [feet-x feet-y height phase move-sign]
  (let [leg-len (* height 0.22)
        leg-spread (* leg-len 0.55)
        stagger (* leg-spread 0.35)
        phase-mul (if (= phase 0) 1 -1)
        move-dir (if (= move-sign 0) 1 (sign move-sign))
        left-x (+ (- feet-x leg-spread) (* move-dir stagger phase-mul -1))
        right-x (+ (+ feet-x leg-spread) (* move-dir stagger phase-mul))]
    {:left [left-x feet-y]
     :right [right-x feet-y]
     :hip-y (- feet-y leg-len)}))

(fn advance-walk-state [walk vx grounded? dt step-px vx-epsilon]
  (let [moving? (and grounded? (> (math.abs vx) vx-epsilon))
        last-sign (if moving? (sign vx) (. walk :last-sign))
        dist-acc (if moving?
                     (+ (. walk :dist-acc) (* (math.abs vx) dt))
                     (. walk :dist-acc))
        phase (. walk :phase)]
    (var new-phase phase)
    (var new-acc dist-acc)
    (while (>= new-acc step-px)
      (set new-acc (- new-acc step-px))
      (set new-phase (if (= new-phase 0) 1 0)))
    {:phase new-phase
     :dist-acc new-acc
     :last-sign last-sign}))

{:sign sign
 :initial-walk-state initial-walk-state
 :foot-positions foot-positions
 :advance-walk-state advance-walk-state}
