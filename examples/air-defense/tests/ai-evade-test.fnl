(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local combat (require :combat))
(local ai (require :ai))
(local flight (require :flight))
(local stats-mod (require :stats))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create-entity (. lux-world :create-entity))
(local get-table-by-id (. lux-world :get-table-by-id))
(local systems (require :systems))

(deftest desired-heading-away-opposes-toward-test
  (testing "flee heading points away from threat"
    (let [toward (flight.desired-heading-to 100 100 200 100)
          away (flight.desired-heading-away 100 100 200 100)
          diff (math.abs (flight.angle-diff toward away))]
      (assert-is (> diff (- math.pi 0.01)))
      (assert-is (< diff (+ math.pi 0.01))))))

(deftest green-hit-puts-red-into-evade-test
  (testing "red plane enters evade toward green attacker after damage"
    (let [game (world.create-game-world)
          w game.world
          stats (stats-mod.initial-stats)
          red-id (create-entity w [:actor :plane
                                   :position 400 200
                                   :velocity 0 0
                                   :heading 0
                                   :hp c.PLANE-HP
                                   :team :red
                                   :plane-ai :strafe 0 0 0])
          green-id (create-entity w [:actor :plane
                                     :position 500 200
                                     :velocity 0 0
                                     :heading math.pi
                                     :hp c.PLANE-HP
                                     :team :green
                                     :plane-ai :hunt 0 0 0])]
      (combat.apply-plane-damage! game w red-id c.BULLET-DMG {:kind :plane :id green-id} stats)
      (let [comps (get-table-by-id w red-id)]
        (assert-eq :evade (. comps.plane-ai 1))
        (assert-eq green-id (. comps.plane-ai 2))
        (assert-eq c.EVADE-DURATION (. comps.plane-ai 4))))))

(deftest evade-expires-red-returns-to-strafe-test
  (testing "after evade duration red resumes building strafe"
    (let [game (world.create-game-world)
          w game.world
          stats (stats-mod.initial-stats)
          state (systems.initial-state game)
          red-id (create-entity w [:actor :plane
                                   :position 400 200
                                   :velocity 50 0
                                   :heading 0
                                   :hp c.PLANE-HP
                                   :team :red
                                   :plane-ai :evade 0 0 c.EVADE-DURATION])]
      (for [i 1 140]
        (systems.step game state (/ c.EVADE-DURATION 120)))
      (let [comps (get-table-by-id w red-id)]
        (assert-eq :strafe (. comps.plane-ai 1))
        (assert-is (> (. comps.plane-ai 2) 0))))))

(deftest turret-hit-evade-flees-turret-test
  (testing "evade with flee-id 0 uses turret position for break-away heading"
    (let [game (world.create-game-world)
          w game.world
          heading (ai.evade-desired-heading game w 400 200 0)]
      (assert-is heading)
      (let [toward-turret (flight.desired-heading-to 400 200 c.TURRET-X c.TURRET-Y)
            diff (math.abs (flight.angle-diff heading toward-turret))]
        (assert-is (> diff 2.5))))))
