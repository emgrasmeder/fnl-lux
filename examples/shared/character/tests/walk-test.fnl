(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local walk (require :shared.character.walk))

(deftest walk-test
  (testing "no distance accumulation when airborne"
    (let [initial (walk.initial-walk-state)
          after (walk.advance-walk-state initial 220 false 0.1 12 5)]
      (assert-eq 0 (. after :dist-acc))
      (assert-eq 0 (. after :phase))))

  (testing "accumulates distance while grounded and moving"
    (let [initial (walk.initial-walk-state)
          after (walk.advance-walk-state initial 220 true 0.1 12 5)]
      (assert-is (> (. after :dist-acc) 0))))

  (testing "toggles phase every step-px of travel"
    (var state (walk.initial-walk-state))
    (set state (walk.advance-walk-state state 120 true 0.05 12 5))
    (assert-eq 0 (. state :phase))
    (set state (walk.advance-walk-state state 120 true 0.05 12 5))
    (assert-eq 1 (. state :phase)))

  (testing "updates last-sign while moving"
    (let [after (walk.advance-walk-state (walk.initial-walk-state) -100 true 0.01 12 5)]
      (assert-eq -1 (. after :last-sign))))

  (testing "foot positions mirror move sign and swap on phase"
    (let [height 36
          feet-x 100
          feet-y 200
          p0 (walk.foot-positions feet-x feet-y height 0 1)
          p1 (walk.foot-positions feet-x feet-y height 1 1)
          left0 (math.abs (- (. p0 :left 1) (. p1 :left 1)))
          right0 (math.abs (- (. p0 :right 1) (. p1 :right 1)))]
      (assert-is (> left0 0))
      (assert-is (> right0 0))
      (let [rightward (walk.foot-positions feet-x feet-y height 0 1)
            leftward (walk.foot-positions feet-x feet-y height 0 -1)]
        (assert-is (> (. leftward :left 1) (. rightward :left 1)))))))
