(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local physics (require :physics))
(local ball (require :ball))
(local c (require :constants))

(deftest gravity-integration-test
  (testing "gravity increases downward velocity"
    (let [body {:x 0 :y 0 :vx 0 :vy 0}]
      (physics.integrate-body body 0.1 false)
      (assert-is (> (. body :vy) 0)))))

(deftest ball-ground-test
  (testing "ball rests on ground"
    (let [state {:x 100 :y (- c.GROUND-Y c.BALL-R 1) :vx 0 :vy 200}]
      (ball.step-ball state 0.05)
      (assert-is (<= (+ (. state :y) c.BALL-R) (+ c.GROUND-Y 0.01))))))

(deftest brick-ground-test
  (testing "brick ground correction lifts body"
    (let [body {:x 100 :y c.GROUND-Y :vx 0 :vy 0 :angle 0 :omega 0
                :inv-i 1 :half c.brick-half}]
      (physics.resolve-brick-ground body)
      (assert-is (<= (+ (. body :y) c.brick-half) (+ c.GROUND-Y 0.01))))))
