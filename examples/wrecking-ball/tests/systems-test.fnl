(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local c (require :constants))

(deftest reset-regenerates-test
  (testing "R reset request rebuilds bricks"
    (math.randomseed 7)
    (let [game (world.create-game-world)
          state (systems.initial-state)]
      (tset state :reset-request true)
      (systems.step game state 0.016)
      (assert-is (> (# (. game :brick-ids)) 0))
      (assert-is (not (. state :reset-request))))))

(deftest accumulator-bounded-test
  (testing "large dt does not exceed max accum steps"
    (math.randomseed 7)
    (let [game (world.create-game-world)
          state (systems.initial-state)]
      (systems.step game state 1.0)
      (assert-is (<= (. state :last-substeps) c.MAX-ACCUM-STEPS)))))
