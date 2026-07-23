(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local c (require :constants))
(local physics (require :physics))

(deftest circle-flat-floor-test
  (testing "circle lands on horizontal segment"
    (let [contact (physics.circle-segment-contact 100 110 c.CAPSULE_R
                                                  0 120 200 120)]
      (assert-is contact.hit)
      (assert-is (> (. contact :pen) 0)))))

(deftest capsule-resolves-penetration-test
  (testing "capsule collision resolves into floor"
    (let [rest-y (- 400 (/ c.CAPSULE_H 2))
          pos {:x 100 :y (- rest-y 20)}
          vel {:vx 0 :vy 400}
          segments [{:x1 0 :y1 400 :x2 800 :y2 400}]]
      (physics.integrate pos vel 0.05 false)
      (let [grounded (physics.collide-capsule pos vel segments)]
        (assert-is grounded)
        (assert-is (< (math.abs (- (. pos :y) rest-y)) 8))))))

(deftest slope-contact-test
  (testing "capsule contacts slope segment"
    (let [contact (physics.capsule-segment-contact 100 200 0 250 200 150)]
      (assert-is contact))))

(deftest no-fall-through-test
  (testing "resting capsule stays on floor after micro-step"
    (let [rest-y (- 400 (/ c.CAPSULE_H 2))
          pos {:x 100 :y rest-y}
          vel {:vx 0 :vy 0}
          segments [{:x1 0 :y1 400 :x2 800 :y2 400}]]
      (physics.integrate pos vel 0.016 true)
      (let [grounded (physics.collide-capsule pos vel segments)]
        (assert-is grounded)
        (assert-is (< (math.abs (- (. pos :y) rest-y)) 8))))))
