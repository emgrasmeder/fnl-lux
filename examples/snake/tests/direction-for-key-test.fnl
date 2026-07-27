(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local systems (require :systems))

(deftest direction-for-key-test
  (testing "direction-for-key maps arrows and WASD"
    (assert-eq :up (systems.direction-for-key "up"))
    (assert-eq :down (systems.direction-for-key "down"))
    (assert-eq :left (systems.direction-for-key "left"))
    (assert-eq :right (systems.direction-for-key "right"))
    (assert-eq :up (systems.direction-for-key "w"))
    (assert-eq :down (systems.direction-for-key "s"))
    (assert-eq :left (systems.direction-for-key "a"))
    (assert-eq :right (systems.direction-for-key "d"))))

(deftest direction-for-key-unknown-test
  (testing "unknown keys map to nil"
    (assert-eq nil (systems.direction-for-key "space"))))
