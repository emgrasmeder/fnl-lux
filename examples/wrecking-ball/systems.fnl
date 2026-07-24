(local world-mod (require :world))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local run-removals (. world-api :run-removals))
(local c (require :constants))
(local crane-mod (require :crane))
(local physics-world (require :physics-world))

(fn mouse-position []
  (if (and _G.love _G.love.mouse (. _G.love.mouse :getPosition))
      (let [pos-fn (. _G.love.mouse :getPosition)
            mx (pos-fn)
            my (or (select 2 (pos-fn)) 0)]
        [mx my])
      [c.BASE-X (- c.BASE-Y c.ARM-LEN)]))

(fn clamp-dt [dt]
  (math.min dt c.MAX-DT))

(fn full-reset! [game state]
  (world-mod.reset-buildings! game)
  (world-mod.reset-crane-and-ball! game)
  (tset state :reset-request false))

(fn step [game state dt]
  (when (. state :reset-request)
    (full-reset! game state))
  (let [[mx my] (mouse-position)
        target (crane-mod.mouse-tip-target mx my c.BASE-X c.BASE-Y)
        sub-dt (clamp-dt dt)]
    (physics-world.step! (. game :physics) (. target :x) (. target :y) sub-dt)
    (let [removals (physics-world.despawn-off-screen! (. game :physics))]
      (when (next removals)
        (run-removals (. game :world) removals)
        (let [kept []]
          (each [_ id (ipairs (. game :brick-ids))]
            (when (not (. removals id))
              (table.insert kept id)))
          (tset game :brick-ids kept))))))

(fn initial-state []
  {:reset-request false})

(fn on-key [state key]
  (when (= key "r")
    (tset state :reset-request true)))

{:initial-state initial-state
 :step step
 :on-key on-key
 :mouse-position mouse-position
 :full-reset! full-reset!}
