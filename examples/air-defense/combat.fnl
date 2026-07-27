(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create-entity (. lux-world :create-entity))
(local get-table-by-id (. lux-world :get-table-by-id))
(local select-entities (. lux-world :select-entities-with-components))
(local run-updates (. lux-world :run-updates))
(local run-removals (. lux-world :run-removals))
(local c (require :constants))
(local flight (require :flight))
(local ai (require :ai))
(local stats-mod (require :stats))

(fn circle-hit? [x1 y1 r1 x2 y2 r2]
  (<= (flight.dist x1 y1 x2 y2) (+ r1 r2)))

(fn spawn-bullet! [w x y vx vy owner damage]
  (create-entity w [:actor :bullet
                    :position x y
                    :velocity vx vy
                    :projectile-meta owner damage 0 0]))

(fn spawn-missile! [w x y target-id stats]
  (stats-mod.record-missile-fired! stats)
  (create-entity w [:actor :missile
                    :position x y
                    :velocity 0 0
                    :projectile-meta :turret c.MISSILE-DMG c.MISSILE-CHASE-TIME target-id]))

(fn apply-plane-damage! [game w plane-id amount source stats]
  (let [comps (get-table-by-id w plane-id)
        hp (- (. comps.hp 1) amount)]
    (when (and comps (= (. comps.actor 1) :plane))
      (case source
        :turret (stats-mod.add-turret-damage! stats amount)
        :green (stats-mod.add-friendly-damage! stats amount)
        _ nil)
      (if (<= hp 0)
          (do
            (when (= (. comps.team 1) :red)
              (stats-mod.record-red-killed! stats))
            (let [[vx vy] comps.velocity]
              (run-updates w {:hp {plane-id [0]}
                              :plane-ai {plane-id [:wreck 0 0 0]}
                              :velocity {plane-id [vx vy]}})))
          (run-updates w {:hp {plane-id [hp]}})))))

(fn apply-building-damage! [game w building-id amount stats]
  (let [comps (get-table-by-id w building-id)]
    (when (and comps (> (. comps.hp 1) 0))
      (let [hp (- (. comps.hp 1) amount)]
        (if (<= hp 0)
            (do (run-updates w {:hp {building-id [0]}})
                (stats-mod.record-building-destroyed! stats))
            (run-updates w {:hp {building-id [hp]}}))))))

(fn kill-plane-as-red! [game w plane-id stats]
  (let [comps (get-table-by-id w plane-id)]
    (when (and comps (= (. comps.team 1) :red) (> (. comps.hp 1) 0))
      (apply-plane-damage! game w plane-id (. comps.hp 1) :turret stats))))

(fn turret-aim-nearest [w turret-x turret-y]
  (ai.nearest-red w turret-x turret-y))

(fn fire-turret! [game w stats fire-timer aim]
  (let [tid (. game :turret-id)
        turret (get-table-by-id w tid)
        [tx ty] turret.position
        target (turret-aim-nearest w tx ty)]
    (var new-aim aim)
    (var new-fire fire-timer)
    (when target
      (let [tp (get-table-by-id w target)
            [px py] tp.position]
        (set new-aim (flight.desired-heading-to tx ty px py))))
    (when (and target (<= new-fire 0))
      (let [bx (+ tx (* (math.cos new-aim) c.TURRET-BARREL-LEN))
            by (+ ty (* (math.sin new-aim) c.TURRET-BARREL-LEN))
            bvx (* c.BULLET-SPEED (math.cos new-aim))
            bvy (* c.BULLET-SPEED (math.sin new-aim))]
        (spawn-bullet! w bx by bvx bvy :turret c.BULLET-DMG)
        (set new-fire c.TURRET-FIRE-INTERVAL)))
    [new-fire new-aim]))

(fn try-plane-fire! [w plane-id comps stats dt]
  (let [team (. comps.team 1)
        [mode target fire-timer aux] comps.plane-ai
        [px py] comps.position
        heading (. comps.heading 1)]
    (var new-fire (- fire-timer dt))
    (when (and (> (. comps.hp 1) 0) (not= mode :wreck) (<= new-fire 0))
      (case team
        :red (when (= mode :strafe)
               (let [bx px
                     by (+ py 10)
                     bvx 0
                     bvy c.BULLET-SPEED]
                 (spawn-bullet! w bx by bvx bvy :red c.BULLET-DMG)
                 (set new-fire c.PLANE-FIRE-INTERVAL)))
        :green (when (> target 0)
                 (let [t (get-table-by-id w target)]
                   (when (and t (> (. t.hp 1) 0))
                     (let [[tx ty] t.position
                           aim (flight.desired-heading-to px py tx ty)
                           bvx (* c.BULLET-SPEED (math.cos aim))
                           bvy (* c.BULLET-SPEED (math.sin aim))
                           bx (+ px (* (math.cos heading) 16))
                           by (+ py (* (math.sin heading) 16))]
                       (spawn-bullet! w bx by bvx bvy :green c.BULLET-DMG)
                       (set new-fire c.PLANE-FIRE-INTERVAL)))))
        _ nil))
    new-fire))

(fn bullet-hits [game w stats removals]
  (each [_ bid (ipairs (select-entities w [:actor :position :projectile-meta :velocity]))]
    (let [comps (get-table-by-id w bid)]
      (when (and comps (= (. comps.actor 1) :bullet))
        (let [[bx by] comps.position
              [owner damage _ _] comps.projectile-meta]
          (each [_ pid (ipairs (select-entities w [:actor :position :hp :team]))]
            (when (not (. removals pid))
              (let [p (get-table-by-id w pid)]
                (when (and p (= (. p.actor 1) :plane) (> (. p.hp 1) 0))
                  (let [team (. p.team 1)]
                    (when (and (or (= owner :turret) (= owner :green))
                               (= team :red)
                               (circle-hit? bx by c.BULLET-R (. p.position 1) (. p.position 2) c.PLANE-R))
                      (apply-plane-damage! game w pid damage owner stats)
                      (tset removals bid true)))))))
          (when (= owner :red)
            (each [_ building-id (ipairs (. game :building-ids))]
              (when (not (. removals bid))
                (let [b (get-table-by-id w building-id)]
                  (when (and b (> (. b.hp 1) 0))
                    (let [[x y] b.position]
                      (when (circle-hit? bx by c.BULLET-R x y c.BUILDING-HIT-R)
                        (apply-building-damage! game w building-id damage stats)
                        (tset removals bid true)))))))))))))

(fn missile-hits [game w stats removals]
  (each [_ mid (ipairs (select-entities w [:actor :position :projectile-meta]))]
    (let [comps (get-table-by-id w mid)]
      (when (and comps (= (. comps.actor 1) :missile) (not (. removals mid)))
        (let [[mx my] comps.position]
          (each [_ pid (ipairs (select-entities w [:actor :position :hp :team]))]
            (let [p (get-table-by-id w pid)]
              (when (and p (= (. p.actor 1) :plane) (= (. p.team 1) :red) (> (. p.hp 1) 0)
                         (circle-hit? mx my c.MISSILE-R (. p.position 1) (. p.position 2) c.PLANE-R))
                (stats-mod.record-missile-hit! stats)
                (kill-plane-as-red! game w pid stats)
                (tset removals mid true)))))))))

(fn wreck-collisions [game w stats removals]
  (each [_ pid (ipairs (select-entities w [:actor :position :velocity :plane-ai]))]
    (let [comps (get-table-by-id w pid)]
      (when (and comps (= (. comps.actor 1) :plane) (= (. comps.plane-ai 1) :wreck))
        (let [[px py] comps.position
              [vx vy] comps.velocity]
          (each [_ building-id (ipairs (. game :building-ids))]
            (let [b (get-table-by-id w building-id)]
              (when (and b (> (. b.hp 1) 0))
                (let [[x y] b.position]
                  (when (circle-hit? px py c.PLANE-R x y c.BUILDING-HIT-R)
                    (apply-building-damage! game w building-id c.WRECK-IMPACT-DMG stats)
                    (tset removals pid true))))))
          (when (>= py c.GROUND-Y)
            (tset removals pid true)))))))

(fn buildings-alive? [game w]
  (var any false)
  (each [_ bid (ipairs (. game :building-ids))]
    (let [b (get-table-by-id w bid)]
      (when (and b (> (. b.hp 1) 0))
        (set any true))))
  any)

{:spawn-bullet! spawn-bullet!
 :spawn-missile! spawn-missile!
 :fire-turret! fire-turret!
 :try-plane-fire! try-plane-fire!
 :bullet-hits bullet-hits
 :missile-hits missile-hits
 :wreck-collisions wreck-collisions
 :buildings-alive? buildings-alive?
 :run-removals run-removals
 :run-updates run-updates
 :get-table-by-id get-table-by-id
 :select-entities select-entities}
