(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local c (require :constants))
(local physics (require :physics))

(deftest gravity-integration-test
  (testing "gravity increases downward velocity"
    (let [pos {:x 0 :y 0}
          vel {:vx 0 :vy 0}]
      (physics.integrate pos vel 0.1 false)
      (assert-is (> (. vel :vy) 0)))))

(deftest jump-apex-test
  (testing "jump impulse produces expected apex height"
    (let [pos {:x 0 :y 100}
          vel {:vx 0 :vy 0}
          apex (physics.max-jump-height)]
      (physics.jump! vel true)
      (var peak (. pos :y))
      (for [_ 1 120]
        (physics.integrate pos vel 0.016 false)
        (set peak (math.min peak (. pos :y))))
      (assert-is (< (math.abs (- (- 100 peak) apex)) 5)))))

(deftest grounded-skips-gravity-test
  (testing "grounded body does not accumulate gravity"
    (let [pos {:x 0 :y 0}
          vel {:vx 0 :vy 0}]
      (physics.integrate pos vel 0.1 true)
      (assert-eq 0 (. vel :vy)))))

(deftest horizontal-input-test
  (testing "horizontal input sets velocity"
    (let [vel {:vx 0 :vy 0}]
      (physics.apply-horizontal-input vel 1 true)
      (assert-eq c.MOVE_SPEED (. vel :vx))
      (physics.apply-horizontal-input vel -1 true)
      (assert-eq (- c.MOVE_SPEED) (. vel :vx)))))
