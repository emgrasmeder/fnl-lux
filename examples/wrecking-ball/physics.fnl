(local c (require :constants))

(fn clamp [v lo hi]
  (math.max lo (math.min hi v)))

(fn dot [ax ay bx by]
  (+ (* ax bx) (* ay by)))

(fn len [x y]
  (math.sqrt (+ (* x x) (* y y))))

(fn normalize [x y]
  (let [l (len x y)]
    (if (< l 1e-9)
        [0 -1]
        [(/ x l) (/ y l)])))

(fn rotate [x y angle]
  (let [co (math.cos angle) si (math.sin angle)]
    [(+ (* x co) (* (- y) si))
     (+ (* x si) (* y co))]))

(fn obb-corners [x y angle half]
  (let [[ax ay] (rotate half 0 angle)
        [bx by] (rotate 0 half angle)
        [cx cy] (rotate (- half) 0 angle)
        [dx dy] (rotate 0 (- half) angle)]
    [[(+ x ax) (+ y ay)]
     [(+ x bx) (+ y by)]
     [(+ x cx) (+ y cy)]
     [(+ x dx) (+ y dy)]]))

(fn world-to-local [px py ox oy angle]
  (let [dx (- px ox)
        dy (- py oy)
        co (math.cos angle)
        si (math.sin angle)]
    [(+ (* dx co) (* dy si))
     (+ (* (- dx) si) (* dy co))]))

(fn circle-obb-contact [cx cy r ox oy angle half]
  (let [[lx ly] (world-to-local cx cy ox oy (- angle))
        clx (clamp lx (- half) half)
        cly (clamp ly (- half) half)
        dx (- lx clx)
        dy (- ly cly)
        dist-sq (+ (* dx dx) (* dy dy))
        r-sq (* r r)]
    (if (<= dist-sq r-sq)
        (let [dist (if (< dist-sq 1e-9) 0 (math.sqrt dist-sq))
              pen (- r dist)
              [wnx wny] (rotate (if (< dist 1e-9) 0 (/ dx (or dist 1)))
                                (if (< dist 1e-9) -1 (/ dy (or dist 1)))
                                angle)]
          {:hit true :pen pen :nx wnx :ny wny :lx lx :ly ly})
        {:hit false})))

(fn overlap-on-axis [corners-a corners-b ax ay]
  (var min-a math.huge)
  (var max-a (- math.huge))
  (var min-b math.huge)
  (var max-b (- math.huge))
  (each [_ corner (ipairs corners-a)]
    (let [p (dot (. corner 1) (. corner 2) ax ay)]
      (set min-a (math.min min-a p))
      (set max-a (math.max max-a p))))
  (each [_ corner (ipairs corners-b)]
    (let [p (dot (. corner 1) (. corner 2) ax ay)]
      (set min-b (math.min min-b p))
      (set max-b (math.max max-b p))))
  (if (or (> min-a max-b) (> min-b max-a))
      nil
      (- (math.min max-a max-b) (math.max min-a min-b))))

(fn obb-axes [angle]
  (let [co (math.cos angle) si (math.sin angle)]
    [[co si] [(- si) co]]))

(fn obb-obb-contact [a b]
  (let [corners-a (obb-corners (. a :x) (. a :y) (. a :angle) c.brick-half)
        corners-b (obb-corners (. b :x) (. b :y) (. b :angle) c.brick-half)
        axes []]
    (each [_ ax (ipairs (obb-axes (. a :angle)))]
      (table.insert axes ax))
    (each [_ ax (ipairs (obb-axes (. b :angle)))]
      (table.insert axes ax))
    (var min-overlap math.huge)
    (var best-nx 0)
    (var best-ny 0)
    (each [_ axis (ipairs axes)]
      (let [[ax ay] axis
            overlap (overlap-on-axis corners-a corners-b ax ay)]
        (when (and overlap (< overlap min-overlap))
          (set min-overlap overlap)
          (set best-nx ax)
          (set best-ny ay))))
    (if (and (< min-overlap math.huge) (> min-overlap 0))
        {:hit true :pen min-overlap :nx best-nx :ny best-ny}
        {:hit false})))

(fn resolve-circle-static [pos vel r nx ny pen restitution]
  (tset pos :x (+ (. pos :x) (* nx pen)))
  (tset pos :y (+ (. pos :y) (* ny pen)))
  (let [vd (dot (. vel :vx) (. vel :vy) nx ny)]
    (when (< vd 0)
      (tset vel :vx (- (. vel :vx) (* (* vd nx) (+ 1 restitution))))
      (tset vel :vy (- (. vel :vy) (* (* vd ny) (+ 1 restitution)))))))

(fn apply-impulse-at [body ix iy nx ny j]
  (tset body :vx (+ (. body :vx) (* j nx)))
  (tset body :vy (+ (. body :vy) (* j ny)))
  (when (. body :inv-i)
    (let [rx (- ix (. body :x))
          ry (- iy (. body :y))
          torque (* j (- (* rx ny) (* ry nx)))]
      (tset body :omega (+ (. body :omega) (* torque (. body :inv-i)))))))

(fn contact-impulse [a b contact mass-a mass-b restitution friction]
  (when (and contact contact.hit)
    (let [nx (. contact :nx)
          ny (. contact :ny)
          pen (. contact :pen)
          ix (+ (. a :x) (* nx (/ c.brick-half 2)))
          iy (+ (. a :y) (* ny (/ c.brick-half 2)))
          inv-mass-a (/ 1 mass-a)
          inv-mass-b (/ 1 mass-b)
          rvx (- (. b :vx) (. a :vx))
          rvy (- (. b :vy) (. a :vy))
          vel-along-n (dot rvx rvy nx ny)]
      (when (< vel-along-n 0)
        (let [j (/ (* (- vel-along-n) (+ 1 restitution))
                    (+ inv-mass-a inv-mass-b))]
          (apply-impulse-at a ix iy nx ny (- j))
          (apply-impulse-at b ix iy nx ny j)))
      (let [sep-a (* pen 0.5)
            sep-b (* pen 0.5)]
        (tset a :x (- (. a :x) (* nx sep-a)))
        (tset a :y (- (. a :y) (* ny sep-a)))
        (tset b :x (+ (. b :x) (* nx sep-b)))
        (tset b :y (+ (. b :y) (* ny sep-b)))))))

(fn integrate-body [body dt grounded?]
  (when (not grounded?)
    (tset body :vy (+ (. body :vy) (* c.GRAVITY dt))))
  (tset body :x (+ (. body :x) (* (. body :vx) dt)))
  (tset body :y (+ (. body :y) (* (. body :vy) dt)))
  (when (. body :omega)
    (tset body :angle (+ (. body :angle) (* (. body :omega) dt)))))

(fn brick-body-from-components [comp]
  (let [half c.brick-half
        i (* c.BRICK-MASS half half (/ 6.0))]
    {:x (. comp.position 1)
     :y (. comp.position 2)
     :vx (. comp.velocity 1)
     :vy (. comp.velocity 2)
     :angle (. comp.rotation 1)
     :omega (. comp.angular-velocity 1)
     :inv-i (/ 1 i)
     :half half}))

(fn sync-brick-components! [comp body]
  (tset comp.position 1 (. body :x))
  (tset comp.position 2 (. body :y))
  (tset comp.velocity 1 (. body :vx))
  (tset comp.velocity 2 (. body :vy))
  (tset comp.rotation 1 (. body :angle))
  (tset comp.angular-velocity 1 (. body :omega)))

(fn resolve-brick-ground [body]
  (let [corners (obb-corners (. body :x) (. body :y) (. body :angle) c.brick-half)]
    (var max-y (- math.huge))
    (each [_ corner (ipairs corners)]
      (set max-y (math.max max-y (. corner 2))))
    (if (> max-y c.GROUND-Y)
        (do
          (tset body :y (- (. body :y) (- max-y c.GROUND-Y)))
          (when (> (. body :vy) 0)
            (tset body :vy (* (- (. body :vy)) c.GROUND-FRICTION)))
          (tset body :omega (* (. body :omega) 0.92))
          true)
        false)))

(fn circle-ground-contact [cx cy r vy]
  (if (> (+ cy r) c.GROUND-Y)
      (let [pen (- (+ cy r) c.GROUND-Y)
            ny -1]
        {:hit true :pen pen :ny ny :grounded true})
      {:hit false}))

{:clamp clamp
 :dot dot
 :len len
 :normalize normalize
 :rotate rotate
 :obb-corners obb-corners
 :circle-obb-contact circle-obb-contact
 :obb-obb-contact obb-obb-contact
 :resolve-circle-static resolve-circle-static
 :contact-impulse contact-impulse
 :integrate-body integrate-body
 :brick-body-from-components brick-body-from-components
 :sync-brick-components! sync-brick-components!
 :resolve-brick-ground resolve-brick-ground
 :circle-ground-contact circle-ground-contact
 :apply-impulse-at apply-impulse-at}
