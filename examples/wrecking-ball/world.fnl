(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local run-removals (. world-api :run-removals))
(local buildings (require :buildings))
(local physics-world (require :physics-world))
(local scoring (require :scoring))

(local component-spec
  {:actor [:kind]
   :brick-color [:r :g :b]
   :brick-meta [:building-id :target?]})

(fn spawn-brick! [game brick-ids spawn score]
  (let [world (. game :world)
        id (create-entity world [:actor :brick
                                 :brick-color (. spawn :r) (. spawn :g) (. spawn :b)
                                 :brick-meta (. spawn :building-id) (. spawn :target?)])]
    (physics-world.spawn-brick! (. game :physics) spawn id)
    (scoring.register-spawn! score spawn id)
    (table.insert brick-ids id)
    id))

(fn clear-bricks! [game brick-ids]
  (physics-world.clear-brick-bodies! (. game :physics))
  (when (> (# brick-ids) 0)
    (let [removals {}]
      (each [_ id (ipairs brick-ids)]
        (tset removals id true))
      (run-removals (. game :world) removals))))

(fn spawn-buildings! [game brick-ids score ?seed]
  (let [{:spawns spawns
         :footprints footprints
         :target-building-id target-id
         :neighbor-ids neighbor-ids} (if ?seed
                                      (buildings.generate-buildings ?seed)
                                      (buildings.generate-buildings))]
    (scoring.begin-round! score target-id neighbor-ids)
    (each [_ spawn (ipairs spawns)]
      (spawn-brick! game brick-ids spawn score))
    (physics-world.settle! (. game :physics))
    {:footprints footprints
     :spawns spawns
     :target-building-id target-id
     :neighbor-ids neighbor-ids}))

(fn create-game-world [?seed]
  (let [world (create component-spec)
        brick-ids []
        physics (physics-world.create!)
        score (scoring.initial-game-score)]
    (spawn-buildings! {:world world :physics physics :brick-ids brick-ids :score score}
                      brick-ids score ?seed)
    {:world world :brick-ids brick-ids :physics physics :score score}))

(fn reset-buildings! [game ?seed]
  (clear-bricks! game (. game :brick-ids))
  (tset game :brick-ids [])
  (spawn-buildings! game (. game :brick-ids) (. game :score) ?seed))

(fn reset-crane-and-ball! [game]
  (physics-world.reset-crane-and-ball! (. game :physics)))

{:component-spec component-spec
 :create-game-world create-game-world
 :reset-buildings! reset-buildings!
 :reset-crane-and-ball! reset-crane-and-ball!
 :spawn-brick! spawn-brick!
 :clear-bricks! clear-bricks!
 :spawn-buildings! spawn-buildings!}
