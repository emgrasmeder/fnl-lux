(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local physics (require :physics))
(local c (require :constants))

(deftest circle-obb-hit-test
  (testing "circle overlapping square reports hit"
    (let [contact (physics.circle-obb-contact 100 100 c.BALL-R
                                              108 100 0 c.brick-half)]
      (assert-is contact.hit)
      (assert-is (> contact.pen 0)))))

(deftest obb-obb-hit-test
  (testing "overlapping rotated boxes report hit"
    (let [a {:x 100 :y 100 :angle 0}
          b {:x 104 :y 100 :angle 0.2}
          contact (physics.obb-obb-contact a b)]
      (assert-is contact.hit))))

(deftest circle-obb-miss-test
  (testing "separated circle and box do not hit"
    (let [contact (physics.circle-obb-contact 50 50 c.BALL-R
                                              200 200 0 c.brick-half)]
      (assert-is (not contact.hit)))))
