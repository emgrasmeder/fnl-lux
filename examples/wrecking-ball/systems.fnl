(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local run-updates (. world-api :run-updates))
(local run-removals (. world-api :run-removals))
(local c (require :constants))
(local crane-mod (require :crane))
(local cable-mod (require :cable))
(local ball-mod (require :ball))
(local physics (require :physics))
(local spatial (require :spatial))
(local world-mod (require :world))

(fn mouse-position []
  (if (and _G.love _G.love.mouse (. _G.love.mouse :getPosition))
      (let [pos-fn (. _G.love.mouse :getPosition)
            mx (pos-fn)
            my (or (select 2 (pos-fn)) 0)]
        [mx my])
      [c.BASE-X (- c.BASE-Y c.ARM-LEN)]))

(fn sync-ball-entity! [game ball]
  (run-updates (. game :world)
               {:position {(. game :ball-id) [(. ball :x) (. ball :y)]}
                :velocity {(. game :ball-id) [(. ball :vx) (. ball :vy)]}}))

(fn brick-off-screen? [comp]
  (let [x (. comp.position 1)
        y (. comp.position 2)
        m c.OFF-SCREEN-MARGIN]
    (or (< x (- m))
        (> x (+ c.WINDOW-W m))
        (< y (- m))
        (> y (+ c.WINDOW-H m)))))

(fn despawn-off-screen! [game]
  (let [removals {}
        kept []]
    (each [_ id (ipairs (. game :brick-ids))]
      (let [comp (get-table-by-id (. game :world) id)]
        (if (and comp (brick-off-screen? comp))
            (tset removals id true)
            (table.insert kept id))))
    (when (next removals)
      (run-removals (. game :world) removals))
    (tset game :brick-ids kept)))

(fn step-bricks [game dt ball]
  (let [grid (. game :spatial-grid)
        get-pos (fn [id]
                  (let [comp (get-table-by-id (. game :world) id)]
                    (when comp {:x (. comp.position 1) :y (. comp.position 2)})))]
    (spatial.rebuild! grid c.SPATIAL-CELL-SIZE (. game :brick-ids) get-pos)
    (each [_ id (ipairs (. game :brick-ids))]
      (let [comp (get-table-by-id (. game :world) id)]
        (when comp
          (let [body (physics.brick-body-from-components comp)]
            (physics.integrate-body body dt false)
            (physics.resolve-brick-ground body)
            (let [contact (physics.circle-obb-contact (. ball :x) (. ball :y) c.BALL-R
                                                      (. body :x) (. body :y) (. body :angle) c.brick-half)]
              (when contact.hit
                (let [nx (. contact :nx)
                      ny (. contact :ny)
                      rvx (- (. ball :vx) (. body :vx))
                      rvy (- (. ball :vy) (. body :vy))
                      vn (physics.dot rvx rvy nx ny)]
                  (when (< vn 0)
                    (let [j (/ (* (- vn) (+ 1 c.RESTITUTION))
                               (+ (/ 1 c.BALL-MASS) (/ 1 c.BRICK-MASS)))]
                      (tset ball :vx (- (. ball :vx) (* j nx (/ 1 c.BALL-MASS))))
                      (tset ball :vy (- (. ball :vy) (* j ny (/ 1 c.BALL-MASS))))
                      (physics.apply-impulse-at body (. body :x) (. body :y) nx ny (* j (/ 1 c.BRICK-MASS)))))
                  (tset body :x (+ (. body :x) (* nx (. contact :pen) 0.5)))
                  (tset body :y (+ (. body :y) (* ny (. contact :pen) 0.5))))))
            (physics.sync-brick-components! comp body)))))
    (each [_ pair (ipairs (spatial.brick-pairs grid))]
      (let [id-a (. pair 1)
            id-b (. pair 2)
            comp-a (get-table-by-id (. game :world) id-a)
            comp-b (get-table-by-id (. game :world) id-b)]
        (when (and comp-a comp-b)
          (let [a (physics.brick-body-from-components comp-a)
                b (physics.brick-body-from-components comp-b)
                contact (physics.obb-obb-contact a b)]
            (when contact.hit
              (physics.contact-impulse a b contact c.BRICK-MASS c.BRICK-MASS c.RESTITUTION c.FRICTION)
              (physics.sync-brick-components! comp-a a)
              (physics.sync-brick-components! comp-b b))))))))

(fn physics-substep [sim-game run-state sub-dt]
  (let [[mx my] (mouse-position)
        target (crane-mod.mouse-tip-target mx my c.BASE-X c.BASE-Y)
        crane (. run-state :crane)
        ball (. run-state :ball)]
    (crane-mod.step-motor crane target sub-dt)
    (ball-mod.step-ball ball sub-dt)
    (cable-mod.step-cable crane ball sub-dt)
    (step-bricks sim-game sub-dt ball)
    (sync-ball-entity! sim-game ball)
    (despawn-off-screen! sim-game)))

(fn initial-state []
  {:crane (crane-mod.initial-crane)
   :ball (ball-mod.initial-ball)
   :accum 0
   :reset-request false
   :last-substeps 0})

(fn on-key [run-state key]
  (when (= key "r")
    (tset run-state :reset-request true)))

(fn full-reset! [sim-game run-state]
  (world-mod.reset-buildings! sim-game)
  (world-mod.reset-crane-and-ball! run-state)
  (tset run-state :accum 0)
  (tset run-state :reset-request false))

(fn step [sim-game run-state dt]
  (when (. run-state :reset-request)
    (full-reset! sim-game run-state))
  (tset run-state :accum (+ (. run-state :accum) dt))
  (var steps 0)
  (while (and (>= (. run-state :accum) c.PHYSICS-DT)
              (< steps c.MAX-ACCUM-STEPS))
    (let [sub-dt (/ c.PHYSICS-DT c.SUBSTEPS)]
      (for [_ 1 c.SUBSTEPS]
        (physics-substep sim-game run-state sub-dt)))
    (tset run-state :accum (- (. run-state :accum) c.PHYSICS-DT))
    (set steps (+ steps 1)))
  (tset run-state :last-substeps steps))

{:initial-state initial-state
 :step step
 :on-key on-key
 :physics-substep physics-substep
 :mouse-position mouse-position
 :full-reset! full-reset!
 :brick-off-screen? brick-off-screen?}
