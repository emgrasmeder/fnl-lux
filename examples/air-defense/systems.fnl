(local c (require :constants))
(local stats-mod (require :stats))
(local spawn (require :spawn))
(local ai (require :ai))
(local flight (require :flight))
(local combat (require :combat))
(local missiles (require :missiles))

(fn initial-state [_game]
  {:phase :playing
   :time-left c.ROUND-TIME
   :outcome nil
   :missile-cooldown 0
   :salvo nil
   :spawn-timer 0
   :grey-spawn-timer 0
   :stats (stats-mod.initial-stats)})

(fn enter-summary! [state outcome]
  (tset state :phase :summary)
  (tset state :outcome outcome))

(fn update-one-plane! [game w state dt pid pos-up vel-up head-up ai-up]
  (let [comps (combat.get-table-by-id w pid)]
    (when (and comps (= (. comps.actor 1) :plane))
      (let [team (. comps.team 1)
            [px py] comps.position
            [vx vy] comps.velocity
            heading (. comps.heading 1)
            [mode _ fire _aux] comps.plane-ai]
        (when (= mode :wreck)
          (let [integ (flight.integrate-wreck px py vx vy dt)]
            (tset pos-up pid [(. integ :x) (. integ :y)])
            (tset vel-up pid [(. integ :vx) (. integ :vy)])))
        (when (and (not= mode :wreck) (> (. comps.hp 1) 0))
          (let [ai-result (case team
                            :red (ai.step-red-ai game w pid comps dt)
                            :green (ai.step-green-ai w pid comps dt)
                            _ (ai.step-grey-ai comps))
                desired (. ai-result :desired)
                speed (case team
                        :red c.RED-SPEED
                        :green c.GREEN-SPEED
                        _ c.GREY-SPEED)
                turn (ai.turn-rate-for team)
                integ (flight.integrate-alive px py heading speed turn desired dt)
                comps* (combat.get-table-by-id w pid)
                new-fire (if (not= team :grey)
                           (combat.try-plane-fire! w pid comps* (. state :stats) dt)
                           (- fire dt))]
            (tset pos-up pid [(. integ :x) (. integ :y)])
            (tset vel-up pid [(. integ :vx) (. integ :vy)])
            (tset head-up pid [(. integ :heading)])
            (tset ai-up pid [(. ai-result :mode) (. ai-result :target) new-fire (. ai-result :aux)])))))))

(fn step-planes [game w state dt]
  (let [pos-up {}
        vel-up {}
        head-up {}
        ai-up {}]
    (each [_ pid (ipairs (combat.select-entities w [:actor :team :position :velocity :heading :hp :plane-ai]))]
      (update-one-plane! game w state dt pid pos-up vel-up head-up ai-up))
    (when (next pos-up) (combat.run-updates w {:position pos-up}))
    (when (next vel-up) (combat.run-updates w {:velocity vel-up}))
    (when (next head-up) (combat.run-updates w {:heading head-up}))
    (when (next ai-up) (combat.run-updates w {:plane-ai ai-up}))))

(fn step-bullets [w dt removals]
  (var pos-up {})
  (each [_ bid (ipairs (combat.select-entities w [:actor :position :velocity]))]
    (let [comps (combat.get-table-by-id w bid)]
      (when (and comps (= (. comps.actor 1) :bullet) (not (. removals bid)))
        (let [[x y] comps.position
              [vx vy] comps.velocity
              nx (+ x (* vx dt))
              ny (+ y (* vy dt))]
          (if (or (< nx -20) (> nx (+ c.WINDOW-W 20)) (< ny -40) (> ny (+ c.GROUND-Y 20)))
              (tset removals bid true)
              (tset pos-up bid [nx ny]))))))
  (when (next pos-up) (combat.run-updates w {:position pos-up})))

(fn step-turret [game w dt state]
  (let [tid (. game :turret-id)
        turret (combat.get-table-by-id w tid)]
    (when turret
      (let [[fire-timer aim] turret.turret-state
            fire-after (- fire-timer dt)
            [new-fire new-aim] (combat.fire-turret! game w (. state :stats) fire-after aim)]
        (combat.run-updates w {:turret-state {tid [new-fire new-aim]}})))))

(fn step-playing [game state dt]
  (let [w (. game :world)
        removals {}]
    (spawn.maintain-spawns! w state dt)
    (step-planes game w state dt)
    (step-turret game w dt state)
    (step-bullets w dt removals)
    (missiles.step-salvo-timers state dt)
    (missiles.try-salvo-launch! game w state (. state :stats))
    (missiles.step-missiles w dt removals)
    (combat.bullet-hits game w (. state :stats) removals)
    (combat.missile-hits game w (. state :stats) removals)
    (combat.wreck-collisions game w (. state :stats) removals)
    (each [_ pid (ipairs (combat.select-entities w [:actor :plane-ai]))]
      (let [comps (combat.get-table-by-id w pid)]
        (when (and comps (= (. comps.plane-ai 1) :done))
          (tset removals pid true))))
    (combat.run-removals w removals)
    (tset state :time-left (- (. state :time-left) dt))
    (when (not (combat.buildings-alive? game w))
      (enter-summary! state :loss))
    (when (and (= (. state :phase) :playing) (<= (. state :time-left) 0))
      (enter-summary! state :win))))

(fn step [game state dt]
  (when (= (. state :phase) :playing)
    (step-playing game state dt)))

(fn on-key [_game state key]
  (case (. state :phase)
    :summary (when (or (= key "r") (= key "return")) :restart)
    :playing (when (and (= key "1") (<= (. state :missile-cooldown) 0) (not (. state :salvo)))
               (missiles.launch-salvo! state))
    _ nil))

{:initial-state initial-state
 :step step
 :on-key on-key
 :enter-summary! enter-summary!}
