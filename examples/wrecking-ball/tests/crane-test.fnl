(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local crane (require :crane))
(local c (require :constants))

(fn dist-to [state target]
  (math.sqrt (+ (math.pow (- (. state :tip-x) (. target :x)) 2)
               (math.pow (- (. state :tip-y) (. target :y)) 2))))

(deftest arm-ground-clamp-test
  (testing "tip clamp keeps arm above ground"
    (let [[tx ty] (crane.clamp-tip-above-ground c.BASE-X c.BASE-Y
                                                 (+ c.BASE-X 40)
                                                 (+ c.GROUND-Y 20))]
      (assert-is (<= (crane.arm-corner-lowest c.BASE-X c.BASE-Y tx ty) c.GROUND-Y)))))

(deftest motor-moves-tip-test
  (testing "motor moves tip toward mouse target"
    (let [state (crane.initial-crane)
          target (crane.mouse-tip-target (+ c.BASE-X 60) (- c.BASE-Y 40)
                                         c.BASE-X c.BASE-Y)
          dist-before (dist-to state target)]
      (for [_ 1 40]
        (crane.step-motor state target 0.016))
      (assert-is (< (dist-to state target) dist-before)))))
