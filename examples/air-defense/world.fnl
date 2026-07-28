(local world (require :io.github.emgrasmeder.lux.world))
(local create (. world :create))
(local create-entity (. world :create-entity))
(local c (require :constants))
(local spawn (require :spawn))

(local component-spec
  {:actor [:kind]
   :position [:x :y]
   :velocity [:vx :vy]
   :heading [:rad]
   :hp [:n]
   :team [:kind]
   ;; :plane-ai — :strafe uses target-id=building, aux-id=building track;
   ;; :evade uses target-id=flee entity (0=turret), aux-id=seconds remaining
   :plane-ai [:mode :target-id :fire-timer :aux-id]
   :projectile-meta [:owner :damage :ttl :lock-id]
   :turret-state [:fire-timer :aim-rad]})

(fn building-positions []
  (let [total-w (- (* c.BUILDING-COUNT (+ c.BUILDING-W c.BUILDING-SPACING)) c.BUILDING-SPACING)
        start-x (- c.TURRET-X (/ total-w 2) (/ c.BUILDING-W 2))
        positions []]
    (for [i 0 (- c.BUILDING-COUNT 1)]
      (table.insert positions
                    {:x (+ start-x (* i (+ c.BUILDING-W c.BUILDING-SPACING)) (/ c.BUILDING-W 2))
                     :y (- c.GROUND-Y (/ c.BUILDING-H 2))}))
    positions))

(fn spawn-turret! [w]
  (create-entity w [:actor :turret
                    :position c.TURRET-X (- c.TURRET-Y 8)
                    :turret-state 0 0]))

(fn spawn-buildings! [w]
  (let [ids []]
    (each [_ pos (ipairs (building-positions))]
      (table.insert ids
                    (create-entity w [:actor :building
                                      :position (. pos :x) (. pos :y)
                                      :hp c.MAX-HP])))
    ids))

(fn create-game-world []
  (let [w (create component-spec)
        turret-id (spawn-turret! w)
        building-ids (spawn-buildings! w)]
    (spawn.seed-initial-air! w)
    {:world w
     :turret-id turret-id
     :building-ids building-ids}))

{:component-spec component-spec
 :building-positions building-positions
 :create-game-world create-game-world}
