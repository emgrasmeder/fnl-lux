(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local cable (require :cable))
(local crane (require :crane))
(local ball (require :ball))
(local c (require :constants))

(deftest slack-cable-test
  (testing "short distance is slack"
    (let [st (cable.cable-state 100 100 130 150)]
      (assert-is (. st :slack)))))

(deftest taut-cable-test
  (testing "long distance is taut"
    (let [st (cable.cable-state 100 100 100 300)]
      (assert-is (not (. st :slack))))))

(deftest tension-slows-tip-test
  (testing "taut cable pulls tip when ball falls"
    (let [crane-state (crane.initial-crane)
          ball-state {:x (+ (. crane-state :tip-x) 10)
                      :y (+ (. crane-state :tip-y) c.CHAIN-LEN 40)
                      :vx 0
                      :vy 400}
          tip-vy-before (. crane-state :tip-vy)]
      (cable.step-cable crane-state ball-state 0.016)
      (assert-is (~= (. crane-state :tip-vy) tip-vy-before)))))
