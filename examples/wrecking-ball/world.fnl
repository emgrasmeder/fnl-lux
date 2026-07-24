(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local run-removals (. world-api :run-removals))
(local buildings (require :buildings))
(local c (require :constants))
(local crane-mod (require :crane))
(local ball-mod (require :ball))

(local component-spec
  {:position [:x :y]
   :velocity [:vx :vy]
   :rotation [:angle]
   :angular-velocity [:omega]
   :actor [:kind]
   :brick-hue [:h]})

(fn spawn-brick! [world brick-ids spawn]
  (let [id (create-entity world [:position (. spawn :x) (. spawn :y)
                                 :velocity 0 0
                                 :rotation 0
                                 :angular-velocity 0
                                 :actor :brick
                                 :brick-hue (. spawn :hue)])]
    (table.insert brick-ids id)
    id))

(fn clear-bricks! [world brick-ids]
  (when (> (# brick-ids) 0)
    (let [removals {}]
      (each [_ id (ipairs brick-ids)]
        (tset removals id true))
      (run-removals world removals))))

(fn spawn-buildings! [world brick-ids]
  (let [{:spawns spawns} (buildings.generate-buildings)]
    (each [_ spawn (ipairs spawns)]
      (spawn-brick! world brick-ids spawn))
    spawns))

(fn create-game-world []
  (let [world (create component-spec)
        brick-ids []
        crane-id (create-entity world [:position c.BASE-X c.BASE-Y
                                       :velocity 0 0
                                       :rotation 0
                                       :angular-velocity 0
                                       :actor :crane
                                       :brick-hue 0])
        ball-id (create-entity world [:position (. (ball-mod.initial-ball) :x)
                                      (. (ball-mod.initial-ball) :y)
                                      :velocity 0 0
                                      :rotation 0
                                      :angular-velocity 0
                                      :actor :ball
                                      :brick-hue 0])]
    (spawn-buildings! world brick-ids)
    {:world world
     :brick-ids brick-ids
     :crane-id crane-id
     :ball-id ball-id
     :spatial-grid {}}))

(fn reset-buildings! [game]
  (clear-bricks! (. game :world) (. game :brick-ids))
  (tset game :brick-ids [])
  (spawn-buildings! (. game :world) (. game :brick-ids)))

(fn reset-crane-and-ball! [state]
  (tset state :crane (crane-mod.initial-crane))
  (tset state :ball (ball-mod.initial-ball)))

{:component-spec component-spec
 :create-game-world create-game-world
 :reset-buildings! reset-buildings!
 :reset-crane-and-ball! reset-crane-and-ball!
 :spawn-brick! spawn-brick!
 :clear-bricks! clear-bricks!}
