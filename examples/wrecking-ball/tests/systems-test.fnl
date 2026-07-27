(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local c (require :constants))

(deftest reset-regenerates-test
  (testing "R reset request rebuilds bricks"
    (math.randomseed 7)
    (let [game (world.create-game-world 7)
          state (systems.initial-state)]
      (tset state :reset-request true)
      (systems.step game state 0.016)
      (assert-is (> (# (. game :brick-ids)) 0))
      (assert-is (not (. state :reset-request))))))

(deftest large-dt-step-test
  (testing "large dt does not error"
    (math.randomseed 7)
    (let [game (world.create-game-world 7)
          state (systems.initial-state)]
      (systems.step game state 1.0)
      (assert-is (> (# (. game :brick-ids)) 0)))))

(deftest enter-advances-round-test
  (testing "Enter ends round and increments counter"
    (math.randomseed 7)
    (let [game (world.create-game-world 7)
          state (systems.initial-state)]
      (systems.on-key game state "return")
      (assert-eq (. state :round) 2)
      (assert-eq (# (. game :score :round-scores)) 1))))

(deftest ten-rounds-summary-test
  (testing "after ten Enter presses summary phase"
    (math.randomseed 7)
    (let [game (world.create-game-world 7)
          state (systems.initial-state)]
      (for [_ 1 c.TOTAL-ROUNDS]
        (systems.on-key game state "return"))
      (assert-eq (. state :phase) :summary)
      (assert-eq (# (. game :score :round-scores)) c.TOTAL-ROUNDS))))
