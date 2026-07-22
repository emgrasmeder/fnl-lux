(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))

(fn default-body []
  (var body [])
  (table.insert body {:row 11 :col 11})
  (table.insert body {:row 11 :col 10})
  (table.insert body {:row 11 :col 9})
  body)

(fn fresh-game [body food direction]
  (world.create-game-from-state body food direction))

(fn standard-game []
  (fresh-game (default-body) {:row 5 :col 5} :right))

(fn head [state]
  (. state.body 1))

(deftest initial-state-test
  (testing "initial state matches world setup"
    (let [game (standard-game)
          state (systems.initial-state game)]
      (assert-is (= :playing state.phase))
      (assert-is (= 3 (systems.score state)))
      (assert-is (= :right state.direction)))))

(deftest move-right-test
  (testing "step-once moves snake right"
    (let [game (standard-game)
          state (systems.initial-state game)]
      (systems.step-once game state nil nil)
      (assert-is (= 12 (. (head state) :col)))
      (assert-is (= 11 (. (. state.body 2) :col)))
      (assert-is (= 10 (. (. state.body 3) :col))))))

(deftest direction-queuing-test
  (testing "apply-direction updates next direction"
    (let [state {:phase :playing :direction :right :next-direction :right :body [] :step-timer 0}]
      (systems.apply-direction state :up)
      (assert-is (= :up state.next-direction)))))

(deftest block-180-test
  (testing "180 degree reversal is ignored"
    (let [state {:phase :playing :direction :right :next-direction :right :body [] :step-timer 0}]
      (systems.apply-direction state :left)
      (assert-is (= :right state.next-direction)))))

(deftest wall-death-test
  (testing "hitting wall ends game"
    (let [game (fresh-game [{:row 2 :col 11} {:row 3 :col 11} {:row 4 :col 11}]
                           {:row 10 :col 10} :up)
          state (systems.initial-state game)]
      (var dead false)
      (systems.step-once game state nil (fn [] (set dead true)))
      (assert-is (= :ended state.phase))
      (assert-is dead))))

(deftest self-collision-death-test
  (testing "running into body ends game"
    (let [game (fresh-game [{:row 12 :col 11} {:row 11 :col 11} {:row 11 :col 12} {:row 12 :col 12}]
                           {:row 5 :col 5} :up)
          state (systems.initial-state game)]
      (var dead false)
      (systems.step-once game state nil (fn [] (set dead true)))
      (assert-is (= :ended state.phase))
      (assert-is dead))))

(deftest eat-growth-test
  (testing "eating food grows snake and respawns food"
    (let [game (fresh-game (default-body) {:row 11 :col 12} :right)
          state (systems.initial-state game)]
      (var eaten false)
      (systems.step-once game state (fn [] (set eaten true)) nil)
      (assert-is eaten)
      (assert-is (= 4 (# state.body)))
      (assert-is (= 12 (. (head state) :col)))
      (let [food (systems.get-food-position game)]
        (assert-is (not (world.positions-equal? food (head state))))))))

(deftest food-respawn-not-on-snake-test
  (testing "respawned food is never on snake"
    (math.randomseed 99)
    (let [game (fresh-game (default-body) {:row 11 :col 12} :right)
          state (systems.initial-state game)]
      (for [i 1 15]
        (systems.step-once game state nil nil)
        (when (= state.phase :playing)
          (let [food (systems.get-food-position game)]
            (assert-is (not (world.occupied-by-body? state.body (. food :row) (. food :col))))))))))

(deftest pause-skips-tick-test
  (testing "paused state does not advance on step"
    (let [game (standard-game)
          state (systems.initial-state game)]
      (tset state :phase :paused)
      (systems.step game state 1.5 nil nil)
      (assert-is (= 11 (. (head state) :col))))))

(deftest toggle-pause-test
  (testing "toggle-pause switches phase"
    (let [state {:phase :playing :body [] :direction :right :next-direction :right :step-timer 0}]
      (systems.toggle-pause state)
      (assert-is (= :paused state.phase))
      (systems.toggle-pause state)
      (assert-is (= :playing state.phase)))))

(deftest overlay-text-test
  (testing "overlay text per phase"
    (assert-is (= "PAUSED" (systems.overlay-text {:phase :paused})))
    (assert-is (= "Game Over — press R" (systems.overlay-text {:phase :ended})))
    (assert-is (not (systems.overlay-text {:phase :playing})))))

(deftest apply-direction-ignored-when-paused-test
  (testing "direction input ignored while paused"
    (let [state {:phase :paused :direction :right :next-direction :right :body [] :step-timer 0}]
      (systems.apply-direction state :up)
      (assert-is (= :right state.next-direction)))))

(deftest score-equals-length-test
  (testing "score equals body length"
    (let [state {:body (default-body) :phase :playing}]
      (assert-is (= 3 (systems.score state))))))
