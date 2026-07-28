(local world-mod (require :io.github.emgrasmeder.lux.world))
(local create-entity (. world-mod :create-entity))
(local select-entities (. world-mod :select-entities-with-components))
(local get-table-by-id (. world-mod :get-table-by-id))
(local c (require :constants))
(local flight (require :flight))

(fn plane-alive? [comps]
  (and comps (= (. comps.actor 1) :plane)
       (> (. comps.hp 1) 0)
       (not= (. comps.plane-ai 1) :wreck)))

(fn count-alive-planes [w]
  (let [ids (select-entities w [:actor :team :hp :plane-ai])]
    (var n 0)
    (each [_ id (ipairs ids)]
      (let [comps (get-table-by-id w id)]
        (when (plane-alive? comps)
          (set n (+ n 1)))))
    n))

(fn count-team [w team-kind]
  (let [ids (select-entities w [:actor :team :hp :position])]
    (var n 0)
    (each [_ id (ipairs ids)]
      (let [comps (get-table-by-id w id)]
        (when (and (plane-alive? comps) (= (. comps.team 1) team-kind))
          (set n (+ n 1)))))
    n))

(fn count-grey-crossing [w]
  (let [ids (select-entities w [:actor :team :plane-ai])]
    (var n 0)
    (each [_ id (ipairs ids)]
      (let [comps (get-table-by-id w id)]
        (when (and comps (= (. comps.team 1) :grey) (not= (. comps.plane-ai 1) :done))
          (set n (+ n 1)))))
    n))

(fn spawn-plane! [w team x y heading]
  (let [speed (case team
                :red c.RED-SPEED
                :green c.GREEN-SPEED
                _ c.GREY-SPEED)
        turn (case team
               :red c.RED-TURN-RATE
               :green c.GREEN-TURN-RATE
               _ 1.8)
        mode (if (= team :grey) :grey_cross :hunt)
        [vx vy] (flight.heading-to-velocity heading speed)]
    (create-entity w [:actor :plane
                      :position x y
                      :velocity vx vy
                      :heading heading
                      :hp c.PLANE-HP
                      :team team
                      :plane-ai mode 0 0 turn])))

(fn random-edge-spawn []
  (if (> (math.random) 0.5)
      {:x -40 :y (+ 80 (* (math.random) (- c.GROUND-Y 160))) :heading 0}
      {:x (+ c.WINDOW-W 40) :y (+ 80 (* (math.random) (- c.GROUND-Y 160))) :heading math.pi}))

(fn random-sky-spawn []
  (let [x (+ 160 (* (math.random) (- c.WINDOW-W 320)))
        y (+ 80 (* (math.random) (- c.GROUND-Y 160)))
        heading (flight.desired-heading-to x y c.TURRET-X (- c.GROUND-Y 120))]
    {:x x :y y :heading heading}))

(fn random-onscreen-inbound-spawn []
  (random-sky-spawn))

(fn spawn-grey-lane! [w]
  (let [from-left (> (math.random) 0.5)
        y (+ 60 (* (math.random) 220))
        exit-x (if from-left (+ c.WINDOW-W 60) -60)
        x (if from-left -40 (+ c.WINDOW-W 40))
        heading (if from-left 0 math.pi)
        [vx vy] (flight.heading-to-velocity heading c.GREY-SPEED)]
    (create-entity w [:actor :plane
                      :position x y
                      :velocity vx vy
                      :heading heading
                      :hp c.PLANE-HP
                      :team :grey
                      :plane-ai :grey_cross 0 0 exit-x])))

(fn seed-initial-air! [w]
  (for [i 1 c.RED-MIN]
    (let [s (random-onscreen-inbound-spawn)]
      (spawn-plane! w :red (. s :x) (. s :y) (. s :heading))))
  (for [i 1 c.GREEN-MIN]
    (let [s (random-edge-spawn)]
      (spawn-plane! w :green (. s :x) (. s :y) (. s :heading))))
  (for [i 1 c.GREY-TARGET]
    (spawn-grey-lane! w)))

(fn maintain-spawns! [_w _state _dt]
  ;; Round uses finite initial seed only; mid-round refill moves to next-round logic.
  nil)

{:plane-alive? plane-alive?
 :count-alive-planes count-alive-planes
 :count-team count-team
 :random-sky-spawn random-sky-spawn
 :spawn-plane! spawn-plane!
 :seed-initial-air! seed-initial-air!
 :maintain-spawns! maintain-spawns!}
