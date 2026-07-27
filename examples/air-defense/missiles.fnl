(local c (require :constants))
(local combat (require :combat))
(local flight (require :flight))
(local ai (require :ai))

(fn launch-salvo! [state]
  (tset state :missile-cooldown c.MISSILE-COOLDOWN)
  (tset state :salvo {:remaining c.SALVO-COUNT :timer 0}))

(fn step-salvo-timers [state dt]
  (when (> (. state :missile-cooldown) 0)
    (tset state :missile-cooldown (math.max 0 (- (. state :missile-cooldown) dt))))
  (let [salvo (. state :salvo)]
    (when salvo
      (tset salvo :timer (- (. salvo :timer) dt)))))

(fn try-salvo-launch! [game w state stats]
  (let [salvo (. state :salvo)]
    (when (and salvo (> (. salvo :remaining) 0) (<= (. salvo :timer) 0))
      (let [tid (. game :turret-id)
            turret (combat.get-table-by-id w tid)]
        (when (and turret (ai.nearest-red w (. turret.position 1) (. turret.position 2)))
          (let [target (ai.nearest-red w (. turret.position 1) (. turret.position 2))
                [tx ty] turret.position
                tp (combat.get-table-by-id w target)
                [px py] tp.position
                aim (flight.desired-heading-to tx ty px py)
                mx (+ tx (* (math.cos aim) c.TURRET-BARREL-LEN))
                my (+ ty (* (math.sin aim) c.TURRET-BARREL-LEN))]
            (combat.spawn-missile! w mx my target stats)))
        (tset salvo :remaining (- (. salvo :remaining) 1))
        (tset salvo :timer c.SALVO-INTERVAL)
        (when (<= (. salvo :remaining) 0)
          (tset state :salvo nil))))))

(fn update-one-missile! [w dt mid removals]
  (let [comps (combat.get-table-by-id w mid)]
    (when (and comps (= (. comps.actor 1) :missile) (not (. removals mid)))
      (let [[mx my] comps.position
            [_ dmg ttl lock-id] comps.projectile-meta
            new-ttl (- ttl dt)]
        (if (<= new-ttl 0)
            (tset removals mid true)
            (let [target (when (> lock-id 0) (combat.get-table-by-id w lock-id))]
              (if (and target (= (. target.actor 1) :plane) (> (. target.hp 1) 0))
                  (let [[tx ty] target.position
                        aim (flight.desired-heading-to mx my tx ty)
                        vx (* c.MISSILE-SPEED (math.cos aim))
                        vy (* c.MISSILE-SPEED (math.sin aim))
                        nx (+ mx (* vx dt))
                        ny (+ my (* vy dt))]
                    (combat.run-updates w {:position {mid [nx ny]}
                                           :velocity {mid [vx vy]}
                                           :projectile-meta {mid [:turret dmg new-ttl lock-id]}}))
                  (combat.run-updates w {:projectile-meta {mid [:turret dmg new-ttl lock-id]}}))))))))

(fn step-missiles [w dt removals]
  (each [_ mid (ipairs (combat.select-entities w [:actor :position :velocity :projectile-meta]))]
    (update-one-missile! w dt mid removals)))

{:launch-salvo! launch-salvo!
 :step-salvo-timers step-salvo-timers
 :try-salvo-launch! try-salvo-launch!
 :step-missiles step-missiles}
