(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local scoring (require :scoring))
(local physics-world (require :physics-world))

(deftest dist-test
  (testing "distance helper"
    (assert-eq (scoring.dist 0 0 3 4) 5)))

(deftest neighbor-penalty-test
  (testing "neighbor removal subtracts travel distance"
    (let [score (scoring.initial-game-score)]
      (scoring.begin-round! score 1 {2 true})
      (scoring.register-spawn! score {:x 0 :y 0 :building-id 2 :target? false} 10)
      (scoring.on-bricks-removed! score {10 {:lux-id 10 :building-id 2 :target? false
                                            :sx 0 :sy 0 :rx 3 :ry 4}})
      (assert-eq (. score :total-score) -5))))

(deftest target-bonus-test
  (testing "round bonus when target cleared"
    (let [score (scoring.initial-game-score)
          pw {:brick-records [{:target? true :body nil}] :chain-len 100}]
      (scoring.begin-round! score 1 {})
      (scoring.register-spawn! score {:x 0 :y 0 :building-id 1 :target? true} 1)
      (let [entry (. (. score :bricks) 1)]
        (tset entry :last-x 6)
        (tset entry :last-y 8))
      (tset pw :brick-records [])
      (let [{:round-bonus bonus :target-cleared cleared} (scoring.end-round! score pw)]
        (assert-is cleared)
        (assert-eq bonus 10)
        (assert-eq (. score :total-score) 10)))))

(deftest target-bonus-blocked-test
  (testing "no bonus if target not fully destroyed"
    (let [score (scoring.initial-game-score)
          pw {:brick-records [{:target? true}] :chain-len 100}]
      (scoring.begin-round! score 1 {})
      (scoring.register-spawn! score {:x 0 :y 0 :building-id 1 :target? true} 1)
      (let [entry (. (. score :bricks) 1)]
        (tset entry :last-x 10)
        (tset entry :last-y 0))
      (let [{:round-bonus bonus} (scoring.end-round! score pw)]
        (assert-eq bonus 0)
        (assert-eq (. score :total-score) 0)))))

(deftest adjacent-buildings-test
  (testing "neighbor detection uses adjacency"
    (local buildings (require :buildings))
    (let [a {:x 0 :y 0 :w 16 :h 16}
          b {:x 16 :y 0 :w 16 :h 16}
          c {:x 40 :y 0 :w 16 :h 16}]
      (assert-is (buildings.rects-adjacent? a b 8))
      (assert-is (not (buildings.rects-adjacent? a c 8))))))

(deftest chain-clamp-test
  (testing "chain length clamps to bounds"
    (local c (require :constants))
    (assert-eq (physics-world.clamp-chain-len 10) c.CHAIN-LEN-MIN)
    (assert-eq (physics-world.clamp-chain-len 999) c.CHAIN-LEN-MAX)))
