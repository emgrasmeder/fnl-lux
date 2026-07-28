(import-macros
 {: deftest : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local c (require :constants))
(local flight (require :flight))

(deftest edge-avoidance-nil-inside-test
  (testing "well inside play area needs no bounds steer"
    (let [h (flight.edge-avoidance-heading (/ c.WINDOW-W 2) 200)]
      (assert-is (not h)))))

(deftest edge-avoidance-left-points-east-test
  (testing "near left edge steers toward +x"
    (let [h (flight.edge-avoidance-heading 20 200)]
      (assert-is h)
      (assert-is (> (math.cos h) 0.3)))))

(deftest edge-avoidance-top-points-down-test
  (testing "near top edge steers downward in screen coords"
    (let [h (flight.edge-avoidance-heading 400 30)]
      (assert-is h)
      (assert-is (> (math.sin h) 0.3)))))

(deftest edge-avoidance-near-ground-steers-up-test
  (testing "near ground band steers upward in screen coords"
    (let [h (flight.edge-avoidance-heading 400 (- c.GROUND-Y 40))]
      (assert-is h)
      (assert-is (< (math.sin h) -0.3)))))
