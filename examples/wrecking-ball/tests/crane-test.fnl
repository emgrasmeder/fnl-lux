(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local crane (require :crane))
(local c (require :constants))

(deftest arm-ground-clamp-test
  (testing "tip clamp keeps arm above ground"
    (let [[tx ty] (crane.clamp-tip-above-ground c.BASE-X c.BASE-Y
                                                 (+ c.BASE-X 40)
                                                 (+ c.GROUND-Y 20))]
      (assert-is (<= (crane.arm-corner-lowest c.BASE-X c.BASE-Y tx ty) c.GROUND-Y)))))

(deftest target-angle-test
  (testing "mouse tip target yields angle toward clamped tip"
    (let [target (crane.mouse-tip-target (+ c.BASE-X 60) (- c.BASE-Y 40)
                                         c.BASE-X c.BASE-Y)
          angle (crane.target-angle (. target :x) (. target :y) c.BASE-X c.BASE-Y)]
      (assert-is (= (type angle) "number"))
      (assert-is (> angle (- math.pi)))
      (assert-is (< angle math.pi)))))

(deftest reach-constants-test
  (testing "arm plus max chain exceeds worst building reach"
    (local buildings (require :buildings))
    (assert-is (>= (buildings.crane-max-reach) (buildings.worst-case-reach-needed)))))
