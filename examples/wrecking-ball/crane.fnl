(local c (require :constants))
(local math-atan2 (or math.atan2
                      (fn [y x] (math.atan y x))))

(fn len [x y]
  (math.sqrt (+ (* x x) (* y y))))

(fn normalize [x y]
  (let [l (len x y)]
    (if (< l 1e-9)
        [0 -1]
        [(/ x l) (/ y l)])))

(fn arm-corner-lowest [base-x base-y tip-x tip-y]
  (let [dx (- tip-x base-x)
        dy (- tip-y base-y)
        l (len dx dy)
        nx (if (< l 1e-9) 0 (/ dx l))
        ny (if (< l 1e-9) -1 (/ dy l))
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
        [nx ny] (normalize dx dy)]
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
        [nx ny] (normalize dx dy)
        tx (+ base-x (* nx c.ARM-LEN))
        ty (+ base-y (* ny c.ARM-LEN))
        [cx cy] (clamp-tip-above-ground base-x base-y tx ty)]
    {:x cx :y cy}))

(fn target-angle [tip-x tip-y base-x base-y]
  (math-atan2 (- tip-y base-y) (- tip-x base-x)))

(fn normalize-angle [a]
  (var x a)
  (while (> x math.pi) (set x (- x (* 2 math.pi))))
  (while (< x (- math.pi)) (set x (+ x (* 2 math.pi))))
  x)

(fn angle-delta [from to]
  (normalize-angle (- to from)))

(fn motor-speed [current-angle target-angle]
  (* c.MOTOR-SPEED-GAIN (angle-delta current-angle target-angle)))

{:arm-corner-lowest arm-corner-lowest
 :mouse-tip-target mouse-tip-target
 :clamp-tip-above-ground clamp-tip-above-ground
 :project-tip-on-arm project-tip-on-arm
 :target-angle target-angle
 :motor-speed motor-speed
 :normalize-angle normalize-angle
 :len len}
