(local c (require :constants))

(fn clamp [v lo hi]
  (math.max lo (math.min hi v)))

(fn dot [ax ay bx by]
  (+ (* ax bx) (* ay by)))

(fn closest-point-on-segment [px py x1 y1 x2 y2]
  (let [dx (- x2 x1)
        dy (- y2 y1)
        len2 (+ (* dx dx) (* dy dy))]
    (if (< len2 1e-9)
        [x1 y1]
        (let [t (clamp (/ (dot (- px x1) (- py y1) dx dy) len2) 0 1)]
          [(+ x1 (* t dx)) (+ y1 (* t dy))]))))

(fn circle-segment-contact [cx cy r x1 y1 x2 y2]
  (let [[qx qy] (closest-point-on-segment cx cy x1 y1 x2 y2)
        dx (- cx qx)
        dy (- cy qy)
        dist-sq (+ (* dx dx) (* dy dy))
        r-sq (* r r)]
    (if (<= dist-sq r-sq)
        (let [dist (if (< dist-sq 1e-9) 0 (math.sqrt dist-sq))
              pen (- r dist)
              nx (if (< dist 1e-9) 0 (/ dx (or dist 1)))
              ny (if (< dist 1e-9) -1 (/ dy (or dist 1)))]
          {:pen pen :nx nx :ny ny :hit true})
        {:hit false})))

(fn capsule-circles [cx cy]
  (let [half (c.capsule-half-body)]
    [[cx (- cy half) c.CAPSULE_R]
     [cx (+ cy half) c.CAPSULE_R]]))

(fn capsule-segment-contact [cx cy x1 y1 x2 y2]
  (var best nil)
  (each [_ [ccx ccy r] (ipairs (capsule-circles cx cy))]
    (let [contact (circle-segment-contact ccx ccy r x1 y1 x2 y2)]
      (when (and contact.hit (or (not best) (> contact.pen (. best :pen))))
        (set best contact))))
  best)

(fn resolve-contact [pos vel contact]
  (let [px (. pos :x)
        py (. pos :y)
        nx (. contact :nx)
        ny (. contact :ny)
        pen (. contact :pen)]
    (tset pos :x (+ px (* nx pen)))
    (tset pos :y (+ py (* ny pen)))
    (when (< (dot (. vel :vx) (. vel :vy) nx ny) 0)
      (let [vd (dot (. vel :vx) (. vel :vy) nx ny)]
        (tset vel :vx (- (. vel :vx) (* vd nx)))
        (tset vel :vy (- (. vel :vy) (* vd ny)))))
    (< ny -0.5)))

(fn collide-capsule [pos vel segments]
  (var grounded false)
  (for [_ 1 4]
    (each [_ seg (ipairs segments)]
      (let [contact (capsule-segment-contact (. pos :x) (. pos :y)
                                             seg.x1 seg.y1 seg.x2 seg.y2)]
        (when (and contact contact.hit)
          (when (resolve-contact pos vel contact)
            (set grounded true))))))
  grounded)

(fn integrate [pos vel dt grounded?]
  (when (not grounded?)
    (tset vel :vy (+ (. vel :vy) (* c.GRAVITY dt))))
  (tset pos :x (+ (. pos :x) (* (. vel :vx) dt)))
  (tset pos :y (+ (. pos :y) (* (. vel :vy) dt))))

(fn apply-horizontal-input [vel move-dir grounded?]
  (let [speed (if grounded? c.MOVE_SPEED (* c.MOVE_SPEED c.AIR_CONTROL))]
    (tset vel :vx (* move-dir speed))))

(fn jump! [vel grounded?]
  (when grounded?
    (tset vel :vy c.JUMP_VEL)))

(fn max-jump-height []
  (/ (* c.JUMP_VEL c.JUMP_VEL) (* 2 c.GRAVITY)))

{:integrate integrate
 :collide-capsule collide-capsule
 :apply-horizontal-input apply-horizontal-input
 :jump! jump!
 :capsule-segment-contact capsule-segment-contact
 :circle-segment-contact circle-segment-contact
 :closest-point-on-segment closest-point-on-segment
 :max-jump-height max-jump-height
 :capsule-circles capsule-circles}
