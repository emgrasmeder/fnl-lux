(local c (require :constants))
(local physics (require :physics))

(fn arm-corner-lowest [base-x base-y tip-x tip-y]
  (let [dx (- tip-x base-x)
        dy (- tip-y base-y)
        len (physics.len dx dy)
        nx (if (< len 1e-9) 0 (/ dx len))
        ny (if (< len 1e-9) -1 (/ dy len))
        px (* (- ny) (/ c.ARM-THICK 2))
        py (* nx (/ c.ARM-THICK 2))
        corners [[base-x base-y] [(+ base-x px) (+ base-y py)]
                 [tip-x tip-y] [(+ tip-x px) (+ tip-y py)]]]
    (var lowest (- math.huge))
    (each [_ corner (ipairs corners)]
      (set lowest (math.max lowest (. corner 2))))
    lowest))

(fn project-tip-on-arm [base-x base-y tip-x tip-y]
  (let [dx (- tip-x base-x)
        dy (- tip-y base-y)
        [nx ny] (physics.normalize dx dy)]
    {:x (+ base-x (* nx c.ARM-LEN))
     :y (+ base-y (* ny c.ARM-LEN))}))

(fn clamp-tip-above-ground [base-x base-y tip-x tip-y]
  (let [proj (project-tip-on-arm base-x base-y tip-x tip-y)
        tx (. proj :x)
        ty (. proj :y)
        lowest (arm-corner-lowest base-x base-y tx ty)]
    (if (> lowest c.GROUND-Y)
        (let [dy (- c.GROUND-Y lowest)
              [cx cy] (clamp-tip-above-ground base-x base-y tx (+ ty dy))]
          [cx cy])
        [tx ty])))

(fn mouse-tip-target [mx my base-x base-y]
  (let [dx (- mx base-x)
        dy (- my base-y)
        [nx ny] (physics.normalize dx dy)
        tx (+ base-x (* nx c.ARM-LEN))
        ty (+ base-y (* ny c.ARM-LEN))
        [cx cy] (clamp-tip-above-ground base-x base-y tx ty)]
    {:x cx :y cy}))

(fn initial-crane []
  {:tip-x c.BASE-X
   :tip-y (- c.BASE-Y c.ARM-LEN)
   :tip-vx 0
   :tip-vy 0})

(fn step-motor [crane target dt]
  (let [ax (* c.MOTOR-K (- (. target :x) (. crane :tip-x)))
        ay (* c.MOTOR-K (- (. target :y) (. crane :tip-y)))
        ax (- ax (* c.MOTOR-DAMP (. crane :tip-vx)))
        ay (- ay (* c.MOTOR-DAMP (. crane :tip-vy)))]
    (tset crane :tip-vx (+ (. crane :tip-vx) (* ax dt)))
    (tset crane :tip-vy (+ (. crane :tip-vy) (* ay dt)))
    (tset crane :tip-x (+ (. crane :tip-x) (* (. crane :tip-vx) dt)))
    (tset crane :tip-y (+ (. crane :tip-y) (* (. crane :tip-vy) dt)))
    (let [proj (project-tip-on-arm c.BASE-X c.BASE-Y (. crane :tip-x) (. crane :tip-y))
          [cx cy] (clamp-tip-above-ground c.BASE-X c.BASE-Y (. proj :x) (. proj :y))]
      (tset crane :tip-x cx)
      (tset crane :tip-y cy)
      crane)))

(fn apply-tip-impulse [crane nx ny impulse]
  (tset crane :tip-vx (+ (. crane :tip-vx) (* impulse nx)))
  (tset crane :tip-vy (+ (. crane :tip-vy) (* impulse ny))))

{:arm-corner-lowest arm-corner-lowest
 :mouse-tip-target mouse-tip-target
 :initial-crane initial-crane
 :step-motor step-motor
 :apply-tip-impulse apply-tip-impulse
 :clamp-tip-above-ground clamp-tip-above-ground
 :project-tip-on-arm project-tip-on-arm}
