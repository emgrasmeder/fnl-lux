(local c (require :constants))

(fn rects-overlap? [a b]
  (and (< (. a :x) (+ (. b :x) (. b :w)))
       (< (. b :x) (+ (. a :x) (. a :w)))
       (< (. a :y) (+ (. b :y) (. b :h)))
       (< (. b :y) (+ (. a :y) (. a :h)))))

(fn in-exclusion-zone? [x y w h]
  (let [cx c.BASE-X
        cy c.BASE-Y
        half-w (+ c.EXCLUDE-RADIUS-X (/ w 2))
        half-h (+ c.EXCLUDE-RADIUS-Y (/ h 2))
        rx (- x (- cx half-w))
        ry (- y (- cy half-h))]
    (and (< rx (* 2 half-w))
         (< ry (* 2 half-h)))))

(fn footprint-pixels [footprint]
  (let [bs c.BRICK-SIZE]
    {:x (. footprint :x)
     :y (. footprint :y)
     :w (* (. footprint :w-bricks) bs)
     :h (* (. footprint :h-bricks) bs)}))

(fn random-footprint [side rng-left rng-right rng-top rng-bottom]
  (let [w (+ c.MIN-BUILDING-W-BRICKS
             (math.random (- c.MAX-BUILDING-W-BRICKS c.MIN-BUILDING-W-BRICKS 1)))
        h (+ c.MIN-BUILDING-H-BRICKS
             (math.random (- c.MAX-BUILDING-H-BRICKS c.MIN-BUILDING-H-BRICKS 1)))
        pw (* w c.BRICK-SIZE)
        ph (* h c.BRICK-SIZE)
        x (+ rng-left (math.random (math.max 0 (- rng-right rng-left pw))))
        y (+ rng-top (math.random (math.max 0 (- rng-bottom rng-top ph))))]
    {:side side :x x :y y :w-bricks w :h-bricks h}))

(fn try-place-footprint [side placed]
  (let [left-min c.SIDE-MARGIN
        left-max (- c.BASE-X c.EXCLUDE-RADIUS-X)
        right-min (+ c.BASE-X c.EXCLUDE-RADIUS-X)
        right-max (- c.WINDOW-W c.SIDE-MARGIN)
        [rng-left rng-right] (if (= side :left)
                               [left-min left-max]
                               [right-min right-max])
        rng-top 40
        rng-bottom (- c.GROUND-Y (* c.MIN-BUILDING-H-BRICKS c.BRICK-SIZE))]
    (var found nil)
    (for [attempt 1 40]
      (when (not found)
        (let [fp (random-footprint side rng-left rng-right rng-top rng-bottom)
              px (footprint-pixels fp)]
          (var ok (not (in-exclusion-zone? (. px :x) (. px :y) (. px :w) (. px :h))))
          (each [_ other (ipairs placed)]
            (when (and ok (rects-overlap? px (footprint-pixels other)))
              (set ok false)))
          (when ok (set found fp)))))
    found))

(fn brick-spawns-for-footprint [fp hue]
  (let [spawns []
        bs c.BRICK-SIZE]
    (for [row 0 (- (. fp :h-bricks) 1)]
      (for [col 0 (- (. fp :w-bricks) 1)]
        (table.insert spawns
                      {:x (+ (. fp :x) (* col bs) (/ bs 2))
                       :y (+ (. fp :y) (* row bs) (/ bs 2))
                       :hue hue})))
    spawns))

(fn count-bricks [footprints]
  (var n 0)
  (each [_ fp (ipairs footprints)]
    (set n (+ n (* (. fp :w-bricks) (. fp :h-bricks)))))
  n)

(fn generate-buildings []
  (var footprints [])
  (var total 0)
  (for [side 1 2]
    (let [side-key (if (= side 1) :left :right)
          num (+ c.BUILDINGS-PER-SIDE-MIN
                 (math.random (- c.BUILDINGS-PER-SIDE-MAX c.BUILDINGS-PER-SIDE-MIN)))]
      (for [_ 1 num]
        (when (< total c.MAX-BRICKS)
          (let [fp (try-place-footprint side-key footprints)]
            (when fp
              (table.insert footprints fp)
              (set total (count-bricks footprints))))))))
  (let [spawns []
        hue-base (math.random 40 80)]
    (each [i fp (ipairs footprints)]
      (let [hue (+ hue-base (* i 37))]
        (each [_ s (ipairs (brick-spawns-for-footprint fp hue))]
          (when (< (# spawns) c.MAX-BRICKS)
            (table.insert spawns s)))))
    {:footprints footprints :spawns spawns}))

{:rects-overlap? rects-overlap?
 :in-exclusion-zone? in-exclusion-zone?
 :footprint-pixels footprint-pixels
 :generate-buildings generate-buildings
 :count-bricks count-bricks
 :brick-spawns-for-footprint brick-spawns-for-footprint}
