(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local tick (require :shared.tick))

(deftest step-on-interval-test
  (testing "step-on-interval fires advance at interval"
    (var count 0)
    (let [state {:step-timer 0}]
      (tick.step-on-interval state 0.5 1.0 (fn [] (set count (+ count 1))))
      (assert-eq 0 count)
      (tick.step-on-interval state 0.6 1.0 (fn [] (set count (+ count 1))))
      (assert-eq 1 count)
      (tick.step-on-interval state 0.9 1.0 (fn [] (set count (+ count 1))))
      (assert-eq 2 count))))
