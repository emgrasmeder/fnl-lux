(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local run-removals (. world-api :run-removals))
(local buildings (require :buildings))
(local physics-world (require :physics-world))

(local component-spec
  {:actor [:kind]
   :brick-hue [:h]})

(fn spawn-brick! [game brick-ids spawn]
  (let [world (. game :world)
        id (create-entity world [:actor :brick
                                 :brick-hue (. spawn :hue)])]
    (physics-world.spawn-brick! (. game :physics) (. spawn :x) (. spawn :y) (. spawn :hue) id)
    (table.insert brick-ids id)
    id))

(fn clear-bricks! [game brick-ids]
  (physics-world.clear-brick-bodies! (. game :physics))
  (when (> (# brick-ids) 0)
    (let [removals {}]
      (each [_ id (ipairs brick-ids)]
        (tset removals id true))
      (run-removals (. game :world) removals))))

(fn spawn-buildings! [game brick-ids]
  (let [{:spawns spawns} (buildings.generate-buildings)]
    (each [_ spawn (ipairs spawns)]
      (spawn-brick! game brick-ids spawn))
    (physics-world.settle! (. game :physics))
    spawns))

(fn create-game-world []
  (let [world (create component-spec)
        brick-ids []
        physics (physics-world.create!)]
    (spawn-buildings! {:world world :physics physics :brick-ids brick-ids}
                      brick-ids)
    {:world world :brick-ids brick-ids :physics physics}))

(fn reset-buildings! [game]
  (clear-bricks! game (. game :brick-ids))
  (tset game :brick-ids [])
  (spawn-buildings! game (. game :brick-ids)))

(fn reset-crane-and-ball! [game]
  (physics-world.reset-crane-and-ball! (. game :physics)))

{:component-spec component-spec
 :create-game-world create-game-world
 :reset-buildings! reset-buildings!
 :reset-crane-and-ball! reset-crane-and-ball!
 :spawn-brick! spawn-brick!
 :clear-bricks! clear-bricks!}
