(local c (require :constants))

(fn clamp [v lo hi]
  (math.max lo (math.min hi v)))

(fn max-dy-for-step [dx]
  (math.min c.MAX_STEP (* c.MAX_SLOPE dx)))

(fn clamp-dy [dy dx]
  (clamp dy (- (max-dy-for-step dx)) (max-dy-for-step dx)))

(fn samples-to-segments [samples]
  (var segments [])
  (for [i 1 (- (# samples) 1)]
    (let [a (. samples i)
          b (. samples (+ i 1))
          x1 (. a :x)
          y1 (. a :y)
          x2 (. b :x)
          y2 (. b :y)]
      (table.insert segments {:x1 x1 :y1 y1 :x2 x2 :y2 y2})))
  segments)

(fn generate-height-profile [pane-index entry-y rng]
  (let [start-x (* pane-index c.PANE_W)
        end-x (* (+ pane-index 1) c.PANE_W)
        samples [{:x start-x :y entry-y}]]
    (var y entry-y)
    (var x start-x)
    (while (< x end-x)
      (let [prev-x x
            next-x (math.min (+ x c.SAMPLE_DX) end-x)
            dx (- next-x prev-x)]
        (when (> dx 0)
          (let [raw-dy (- (rng) 0.5)
                scaled (* raw-dy (* 2 (max-dy-for-step dx)))
                dy (clamp-dy scaled dx)]
            (set y (clamp (+ y dy) c.FLOOR_MIN c.FLOOR_MAX))
            (table.insert samples {:x next-x :y y})))
        (set x next-x)))
    samples))

(fn generate-pane [pane-index entry-y]
  (let [samples (generate-height-profile pane-index entry-y math.random)
        segments (samples-to-segments samples)
        last-sample (. samples (# samples))]
    {:index pane-index
     :segments segments
     :entry-y entry-y
     :exit-y (. last-sample :y)
     :start-x (* pane-index c.PANE_W)
     :end-x (* (+ pane-index 1) c.PANE_W)}))

(fn segment-slope [seg]
  (let [dx (- seg.x2 seg.x1)
        dy (- seg.y2 seg.y1)]
    (if (< (math.abs dx) 1e-9)
        0
        (/ dy dx))))

(fn pane-valid? [pane]
  (let [samples []]
    (each [_ seg (ipairs pane.segments)]
      (table.insert samples {:x seg.x1 :y seg.y1}))
    (when (> (# pane.segments) 0)
      (let [last (. pane.segments (# pane.segments))]
        (table.insert samples {:x last.x2 :y last.y2})))
    (var valid true)
    (for [i 1 (- (# samples) 1)]
      (let [a (. samples i)
            b (. samples (+ i 1))
            dx (- (. b :x) (. a :x))
            dy (- (. b :y) (. a :y))]
        (when (and (> (math.abs dx) 1e-9)
                   (or (> (math.abs dy) c.MAX_STEP)
                       (> (math.abs (/ dy dx)) c.MAX_SLOPE)))
          (set valid false))))
    (and valid (> (# pane.segments) 0))))

(fn floor-y-at [pane x]
  (var result nil)
  (each [_ seg (ipairs pane.segments)]
    (when (and (>= x seg.x1) (<= x seg.x2))
      (let [t (/ (- x seg.x1) (- seg.x2 seg.x1))]
        (set result (+ seg.y1 (* t (- seg.y2 seg.y1)))))))
  result)

{:generate-pane generate-pane
 :pane-valid? pane-valid?
 :segment-slope segment-slope
 :floor-y-at floor-y-at
 :samples-to-segments samples-to-segments
 :clamp-dy clamp-dy
 :max-dy-for-step max-dy-for-step}
