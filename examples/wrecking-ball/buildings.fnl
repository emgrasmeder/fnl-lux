(local c (require :constants))

(fn rects-overlap? [a b]
  (and (< (. a :x) (+ (. b :x) (. b :w)))
       (< (. b :x) (+ (. a :x) (. a :w)))
       (< (. a :y) (+ (. b :y) (. b :h)))
       (< (. b :y) (+ (. a :y) (. a :h)))))

(fn rects-adjacent? [a b margin]
  (let [m (or margin c.BRICK-SIZE)
        ax1 (. a :x)
        ay1 (. a :y)
        ax2 (+ ax1 (. a :w))
        ay2 (+ ay1 (. a :h))
        bx1 (. b :x)
        by1 (. b :y)
        bx2 (+ bx1 (. b :w))
        by2 (+ by1 (. b :h))
        x-overlap (and (< ax1 (+ bx2 m)) (< bx1 (+ ax2 m)))
        y-overlap (and (< ay1 (+ by2 m)) (< by1 (+ ay2 m)))
        touch-x (and x-overlap (or (<= (math.abs (- ax2 bx1)) m)
                                   (<= (math.abs (- bx2 ax1)) m)))
        touch-y (and y-overlap (or (<= (math.abs (- ay2 by1)) m)
                                   (<= (math.abs (- by2 ay1)) m)))]
    (and (not (rects-overlap? a b))
         (or touch-x touch-y))))

(fn in-exclusion-zone? [x y w h]
  (let [cx c.BASE-X
        cy c.BASE-Y
        zone {:x (- cx c.EXCLUDE-RADIUS-X)
              :y (- cy c.EXCLUDE-RADIUS-Y)
              :w (* 2 c.EXCLUDE-RADIUS-X)
              :h (* 2 c.EXCLUDE-RADIUS-Y)}
        building {:x x :y y :w w :h h}]
    (rects-overlap? building zone)))

(fn footprint-pixels [footprint]
  (let [bs c.BRICK-SIZE]
    {:x (. footprint :x)
     :y (. footprint :y)
     :w (* (. footprint :w-bricks) bs)
     :h (* (. footprint :h-bricks) bs)}))

(fn footprint-y-on-ground [h-bricks]
  (- c.GROUND-Y (* h-bricks c.BRICK-SIZE)))

(fn random-pastel-rgb []
  (let [h (math.random 0 359)
        s (+ 0.35 (* (math.random) 0.25))
        val (+ 0.78 (* (math.random) 0.15))
        chroma val
        x (* chroma (- 1 (math.abs (% (+ (/ h 60) 2) 2) 1)))]
    (if (< h 60) [chroma x 0]
        (if (< h 120) [x chroma 0]
            (if (< h 180) [0 chroma x]
                (if (< h 240) [0 x chroma]
                    (if (< h 300) [x 0 chroma]
                        [chroma 0 x])))))))

(fn target-rgb [] [0.85 0.15 0.15])

(fn random-footprint [side rng-left rng-right building-id]
  (let [w (+ c.MIN-BUILDING-W-BRICKS
             (math.random (- c.MAX-BUILDING-W-BRICKS c.MIN-BUILDING-W-BRICKS 1)))
        h (+ c.MIN-BUILDING-H-BRICKS
             (math.random (- c.MAX-BUILDING-H-BRICKS c.MIN-BUILDING-H-BRICKS 1)))
        pw (* w c.BRICK-SIZE)
        x (+ rng-left (math.random (math.max 0 (- rng-right rng-left pw))))
        y (footprint-y-on-ground h)
        [r g b] (random-pastel-rgb)]
    {:building-id building-id
     :side side
     :x x
     :y y
     :w-bricks w
     :h-bricks h
     :target? false
     :r r
     :g g
     :b b}))

(fn side-ranges [side]
  (let [left-min c.SIDE-MARGIN
        left-max (- c.BASE-X c.EXCLUDE-RADIUS-X)
        right-min (+ c.BASE-X c.EXCLUDE-RADIUS-X)
        right-max (- c.WINDOW-W c.SIDE-MARGIN)]
    (if (= side :left)
        [left-min left-max]
        [right-min right-max])))

(fn try-place-footprint [side placed next-id]
  (let [[rng-left rng-right] (side-ranges side)]
    (var found nil)
    (for [attempt 1 40]
      (when (not found)
        (let [fp (random-footprint side rng-left rng-right next-id)
              px (footprint-pixels fp)]
          (var ok (not (in-exclusion-zone? (. px :x) (. px :y) (. px :w) (. px :h))))
          (each [_ other (ipairs placed)]
            (when (and ok (rects-overlap? px (footprint-pixels other)))
              (set ok false)))
          (when ok (set found fp)))))
    found))

(fn forced-footprint [side placed building-id]
  (let [w c.MIN-BUILDING-W-BRICKS
        h c.MIN-BUILDING-H-BRICKS
        pw (* w c.BRICK-SIZE)
        [rng-left rng-right] (side-ranges side)
        start-x (if (= side :left) rng-left (- rng-right pw))
        step (if (= side :left) c.BRICK-SIZE (- c.BRICK-SIZE))
        y (footprint-y-on-ground h)
        [r g b] (random-pastel-rgb)]
    (var x start-x)
    (var found nil)
    (while (and (not found) (if (= side :left) (<= x (- rng-right pw)) (>= x rng-left)))
      (let [fp {:building-id building-id :side side :x x :y y
                :w-bricks w :h-bricks h :target? false :r r :g g :b b}
            px (footprint-pixels fp)]
        (var ok (not (in-exclusion-zone? (. px :x) (. px :y) (. px :w) (. px :h))))
        (each [_ other (ipairs placed)]
          (when (and ok (rects-overlap? px (footprint-pixels other)))
            (set ok false)))
        (if ok (set found fp) (set x (+ x step)))))
    found))

(fn ensure-side-footprint! [side placed next-id]
  (or (try-place-footprint side placed next-id)
      (try-place-footprint side placed (+ next-id 1000))
      (forced-footprint side placed next-id)))

(fn mark-target! [footprints]
  (when (> (# footprints) 0)
    (let [idx (math.random 1 (# footprints))
          [r g b] (target-rgb)]
      (each [i fp (ipairs footprints)]
        (tset fp :target? (= i idx))
        (when (= i idx)
          (tset fp :r r)
          (tset fp :g g)
          (tset fp :b b))))))

(fn neighbor-building-ids [footprints]
  (var target-id nil)
  (each [_ fp (ipairs footprints)]
    (when (. fp :target?) (set target-id (. fp :building-id))))
  (let [neighbors {}]
    (when target-id
      (var target-px nil)
      (each [_ fp (ipairs footprints)]
        (when (. fp :target?) (set target-px (footprint-pixels fp))))
      (when target-px
        (each [_ fp (ipairs footprints)]
          (when (not (. fp :target?))
            (when (rects-adjacent? target-px (footprint-pixels fp) c.BRICK-SIZE)
              (tset neighbors (. fp :building-id) true))))))
    {:target-building-id target-id :neighbor-ids neighbors}))

(fn brick-spawns-for-footprint [fp]
  (let [spawns []
        bs c.BRICK-SIZE]
    (for [row 0 (- (. fp :h-bricks) 1)]
      (for [col 0 (- (. fp :w-bricks) 1)]
        (table.insert spawns
                      {:x (+ (. fp :x) (* col bs) (/ bs 2))
                       :y (+ (. fp :y) (* row bs) (/ bs 2))
                       :building-id (. fp :building-id)
                       :target? (. fp :target?)
                       :r (. fp :r)
                       :g (. fp :g)
                       :b (. fp :b)})))
    spawns))

(fn count-bricks [footprints]
  (var n 0)
  (each [_ fp (ipairs footprints)]
    (set n (+ n (* (. fp :w-bricks) (. fp :h-bricks)))))
  n)

(fn generate-buildings [?seed]
  (when ?seed (math.randomseed ?seed))
  (var footprints [])
  (var next-id 1)
  (for [i 1 2]
    (let [side (if (= i 1) :left :right)
          fp (ensure-side-footprint! side footprints next-id)]
      (when fp
        (table.insert footprints fp)
        (set next-id (+ next-id 1)))))
  (var total (count-bricks footprints))
  (for [side 1 2]
    (let [side-key (if (= side 1) :left :right)
          num (+ c.BUILDINGS-PER-SIDE-MIN
                 (math.random (- c.BUILDINGS-PER-SIDE-MAX c.BUILDINGS-PER-SIDE-MIN)))]
      (for [_ 1 num]
        (when (< total c.MAX-BRICKS)
          (let [fp (try-place-footprint side-key footprints next-id)]
            (when fp
              (table.insert footprints fp)
              (set next-id (+ next-id 1))
              (set total (count-bricks footprints))))))))
  (mark-target! footprints)
  (let [spawns []
        {:target-building-id target-id
         :neighbor-ids neighbor-ids} (neighbor-building-ids footprints)]
    (each [_ fp (ipairs footprints)]
      (each [_ s (ipairs (brick-spawns-for-footprint fp))]
        (when (< (# spawns) c.MAX-BRICKS)
          (table.insert spawns s))))
    {:footprints footprints
     :spawns spawns
     :target-building-id target-id
     :neighbor-ids neighbor-ids}))

(fn worst-case-reach-needed []
  (let [bs c.BRICK-SIZE
        top-y (- c.GROUND-Y (* c.MAX-BUILDING-H-BRICKS bs))
        corner-x c.SIDE-MARGIN
        dx (- c.BASE-X corner-x)
        dy (- c.BASE-Y top-y)]
    (math.sqrt (+ (* dx dx) (* dy dy)))))

(fn crane-max-reach []
  (+ c.ARM-LEN c.CHAIN-LEN-MAX c.BALL-R))

{:rects-overlap? rects-overlap?
 :rects-adjacent? rects-adjacent?
 :in-exclusion-zone? in-exclusion-zone?
 :footprint-pixels footprint-pixels
 :footprint-y-on-ground footprint-y-on-ground
 :generate-buildings generate-buildings
 :neighbor-building-ids neighbor-building-ids
 :count-bricks count-bricks
 :brick-spawns-for-footprint brick-spawns-for-footprint
 :worst-case-reach-needed worst-case-reach-needed
 :crane-max-reach crane-max-reach}
