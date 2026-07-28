(import-macros
 {: deftest : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local combat (require :combat))
(local flight (require :flight))
(local stats-mod (require :stats))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create (. lux-world :create))
(local create-entity (. lux-world :create-entity))
(local select-entities (. lux-world :select-entities-with-components))

(fn count-bullets [w]
  (var n 0)
  (each [_ id (ipairs (select-entities w [:actor]))]
    (let [comps (combat.get-table-by-id w id)]
      (when (and comps (= (. comps.actor 1) :bullet))
        (set n (+ n 1)))))
  n)

(deftest turret-aims-at-distant-red-test
  (testing "turret tracks nearest red with no range limit"
    (let [w (create world.component-spec)
          tid (create-entity w [:actor :turret
                                :position c.TURRET-X (- c.TURRET-Y 8)
                                :turret-state 0 0])
          _red-id (create-entity w [:actor :plane
                                     :position -500 150
                                     :velocity 0 0
                                     :heading 0
                                     :hp c.PLANE-HP
                                     :team :red
                                     :plane-ai :strafe 0 0 0])
          game {:world w :turret-id tid :building-ids []}
          stats (stats-mod.initial-stats)
          tx c.TURRET-X
          ty (- c.TURRET-Y 8)
          expected (flight.desired-heading-to tx ty -500 150)
          [_ new-aim] (combat.fire-turret! game w stats 0 0)]
      (assert-is (< (math.abs (flight.angle-diff new-aim expected)) 0.01))
      (assert-is (> (count-bullets w) 0)))))
