(local world-mod (require :world))
(local world (require :io.github.emgrasmeder.lux.world))
(local run-removals (. world :run-removals))
(local c (require :constants))
(local crane-mod (require :crane))
(local physics-world (require :physics-world))
(local scoring (require :scoring))

(fn mouse-position []
  (if (and _G.love _G.love.mouse (. _G.love.mouse :getPosition))
      (let [pos-fn (. _G.love.mouse :getPosition)
            mx (pos-fn)
            my (or (select 2 (pos-fn)) 0)]
        [mx my])
      [c.BASE-X (- c.BASE-Y c.ARM-LEN)]))

(fn clamp-dt [dt]
  (math.min dt c.MAX-DT))

(fn playing? [state]
  (= (. state :phase) :playing))

(fn start-new-run! [game state]
  (scoring.reset-game-score! (. game :score))
  (tset state :round 1)
  (tset state :phase :playing)
  (world-mod.reset-buildings! game)
  (world-mod.reset-crane-and-ball! game))

(fn advance-round! [game state]
  (scoring.end-round! (. game :score) (. game :physics))
  (let [next-round (+ (. state :round) 1)]
    (if (> next-round c.TOTAL-ROUNDS)
        (tset state :phase :summary)
        (do
          (tset state :round next-round)
          (world-mod.reset-buildings! game)
          (world-mod.reset-crane-and-ball! game)))))

(fn full-reset! [game state]
  (start-new-run! game state)
  (tset state :reset-request false))

(fn handle-removals! [game removed-by-id]
  (when (next removed-by-id)
    (scoring.on-bricks-removed! (. game :score) removed-by-id)
    (let [lux-ids {}]
      (each [id _ (pairs removed-by-id)]
        (tset lux-ids id true))
      (run-removals (. game :world) lux-ids)
      (let [kept []]
        (each [_ id (ipairs (. game :brick-ids))]
          (when (not (. lux-ids id))
            (table.insert kept id)))
        (tset game :brick-ids kept)))))

(fn step [game state dt]
  (when (. state :reset-request)
    (full-reset! game state))
  (when (playing? state)
    (let [[mx my] (mouse-position)
          target (crane-mod.mouse-tip-target mx my c.BASE-X c.BASE-Y)
          sub-dt (clamp-dt dt)]
      (physics-world.step! (. game :physics) (. target :x) (. target :y) sub-dt)
      (handle-removals! game (physics-world.despawn-off-screen! (. game :physics))))))

(fn initial-state []
  {:reset-request false
   :phase :playing
   :round 1})

(fn on-key [game state key]
  (when (= key "r")
    (tset state :reset-request true))
  (when (= key "return")
    (if (= (. state :phase) :summary)
        (start-new-run! game state)
        (advance-round! game state))))

(fn on-wheel [game state y]
  (when (and (playing? state) (not= y 0))
    (let [pw (. game :physics)
          delta (* y c.CHAIN-WHEEL-STEP)
          new-len (+ (. pw :chain-len) delta)]
      (physics-world.set-chain-len! pw new-len))))

{:initial-state initial-state
 :step step
 :on-key on-key
 :on-wheel on-wheel
 :mouse-position mouse-position
 :full-reset! full-reset!
 :advance-round! advance-round!
 :start-new-run! start-new-run!}
