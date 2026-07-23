(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local c (require :constants))
(local camera (require :camera))
(local terrain (require :terrain))

(fn create-game-world []
  (let [world (create {:position [:x :y]
                       :velocity [:vx :vy]
                       :grounded [:flag]
                       :actor [:kind]})
        cam-state (camera.initial-state)]
    (camera.ensure-pane! cam-state 0 c.FLOOR_BASE)
    (let [pane0 (. cam-state.panes 0)
          start-x (+ c.CAPSULE_R 20)
          floor-y (or (terrain.floor-y-at pane0 start-x) c.FLOOR_BASE)
          start-y (- floor-y (/ c.CAPSULE_H 2))
          player-id (create-entity world [:position start-x start-y
                                          :velocity 0 0
                                          :grounded true
                                          :actor :player])]
      {:world world
       :player-id player-id
       :cam-state cam-state})))

{:create-game-world create-game-world}
